#JAVA_OPTS="-Xmx70G"
#TARGET=/scratch/balhoff/phenoscape-kb
#get KB sources
#KB_SOURCES: get_sources.sh
#	$HOME/phenoscape-owl-tools/get_sources.sh
#building KB
#semantic similarity processing
#BUILD_KB: KB_SOURCES
#	$HOME/phenoscape-owl-tools/target/universal/stage/bin/kb-owl-tools build-kb $TARGET $HOME/phenoscape-owl-tools/blazegraph.properties

PROJECT_DIR:=/Users/shalkishrivastava/renci/Phenoscape/PhenoscapeOwlTools
TARGET:=${PROJECT_DIR}/phenoscape-owl-tools/run/phenoscape-kb
PIPELINE:=${PROJECT_DIR}/phenoscape-owl-tools/pipeline

BUILD_DIR=build
ROBOT_ENV=ROBOT_JAVA_ARGS=-Xmx12G
ROBOT=$(ROBOT_ENV) robot

all: $(BUILD_DIR)/phenoscape-ontology-classified.ofn

clean:
	rm -rf build

# Ontologies.ofn - list of ontologies to be imported
# Mirror ontologies locally
$(BUILD_DIR)/mirror: ontologies.ofn
	mkdir -p $(BUILD_DIR) && rm -rf $@ &&\
	$(ROBOT) mirror -i $< -d $@ -o $@/catalog-v001.xml

# Extract ontology metadata
$(BUILD_DIR)/ontology-metadata: ontologies.ofn ontology-versions.sparql
	mkdir -p (BUILD_DIR)/ontology-metadata \
	$(ROBOT) query -i $< --use-graphs true --queries ontology-versions.sparql --output-dir $@


# Merge imported ontologies
$(BUILD_DIR)/phenoscape-ontology.ofn: ontologies.ofn $(BUILD_DIR)/mirror
	$(ROBOT) merge --catalog $(BUILD_DIR)/mirror/catalog-v001.xml -i $< -o $@

# Compute inferred classification of just the input ontologies.
# We need to remove axioms that can infer unsatisfiability, since
# the input ontologies are not 100% compatible.
$(BUILD_DIR)/phenoscape-ontology-classified.ofn: $(BUILD_DIR)/phenoscape-ontology.ofn
	$(ROBOT) remove -i $< --axioms 'disjoint' --trim true \
	remove --term 'owl:Nothing' --trim true \
	reason --reasoner ELK -o $@


# Extract Qualities from ontology
$(BUILD_DIR)/qualities.txt: $(BUILD_DIR)/phenoscape-ontology-classified.ofn qualities.sparql
	$(ROBOT) query -i $< --use-graphs true --query qualities.sparql $@

# Extract Anatomical-Entities from ontology
$(BUILD_DIR)/anatomical_entities.txt: $(BUILD_DIR)/phenoscape-ontology-classified.ofn anatomicalEntities.sparql
	$(ROBOT) query -i $< --use-graphs true --query anatomicaEntities.sparql $@

# Create Query-Subsumers
$(BUILD_DIR)/query-subsumers.ofn: $(BUILD_DIR)/qualities.txt $(BUILD_DIR)/anatomical_entities.txt


# Create Similarity-Subsumers
$(BUILD_DIR)/similarity-subsumers.ofn: $(BUILD_DIR)/qualities.txt $(BUILD_DIR)/anatomical_entities.txt

# Download annotated data from Phenex
$(BUILD_DIR)/phenoscape-data:
	git clone https://github.com/phenoscape/phenoscape-data.git $@

# Store paths to all needed NeXML files in NEXMLS variable
NEXMLS := $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/completed-phenex-files -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/fin_limb-incomplete-files -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/Jackson_Dissertation_Files -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/teleost-incomplete-files/Miniature_Monographs -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/teleost-incomplete-files/Miniatures_Matrix_Files -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/matrix-vs-monograph -type f -name "*.xml")

# Store paths to all OFN files which will be produced from NeXML files in NEXML_OWLS variable
NEXML_OWLS := $(patsubst %.xml, %.ofn, $(patsubst $(BUILD_DIR)/phenoscape-data/%, $(BUILD_DIR)/phenoscape-data-owl/%, $(NEXMLS)))

# Convert a single NeXML file to its counterpart OFN
$(BUILD_DIR)/phenoscape-data-owl/%.ofn: $(BUILD_DIR)/phenoscape-data/%.xml $(BUILD_DIR)/phenoscape-ontology.ofn
	convert-nexml $(BUILD_DIR)/phenoscape-ontology.ofn $< $@
	echo "Build" $@ using $<
# Use kb-owl-tools phenex-to-owl to convert

# Merge all NeXML OFN files into a single ontology of phenotype annotations
$(BUILD_DIR)/phenoscape-data.ofn: $(NEXML_OWLS)
	$(ROBOT) merge $(addprefix -i , $<) -o $@
	echo "Merge data ontologies"


# Extract tbox and rbox from phenoscape-data.ofn
$(BUILD_DIR)/phenoscape-data-tbox.ofn: $(BUILD_DIR)/phenoscape-data.ofn
	$(ROBOT) filter -i $< --axioms tbox --axioms rbox -o $@

# Create Phenoscape KB Tbox
$(BUILD_DIR)/phenoscape-kb-tbox.ofn: $(BUILD_DIR)/phenoscape-data-tbox.ofn $(BUILD_DIR)/phenoscape-ontology-classified.ofn $(BUILD_DIR)/query-subsumers.ofn $(BUILD_DIR)/similarity-subsumers.ofn
	$(ROBOT) merge -i $< \
	-i $(BUILD_DIR)/phenoscape-ontology-classified.ofn \
	-i $(BUILD_DIR)/query-subsumers.ofn \
	-i $(BUILD_DIR)/similarity-subsumers.ofn \
	-o $@


# Compute inferred classification of Phenoscpae KB Tbox
$(BUILD_DIR)/phenoscape-kb-tbox-classified.ofn: $(BUILD_DIR)/phenoscape-kb-tbox.ofn
	$(ROBOT) reason --reasoner ELK --i $< -o $@


# Compute Tbox hierarchy
$(BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ofn: $(BUILD_DIR)/phenoscape-kb-tbox-classified.ofn
	$(ROBOT) filter -i $< --axioms subclass -o $@

# Create Phenoscape data KB
$(BUILD_DIR)/phenoscape-data-kb.ofn: $(BUILD_DIR)/phenoscape-data.ofn $(BUILD_DIR)/phenoscape-kb-tbox-classified.ofn


# Generate absences.ttl
$(BUILD_DIR)/absences.ttl: $(BUILD_DIR)/phenoscape-data-kb.ofn

# Generate presences.ttl
$(BUILD_DIR)/presences.ttl: $(BUILD_DIR)/phenoscape-data-kb.ofn

# Generate taxon-profiles.ttl
$(BUILD_DIR)/taxon-profiles.ttl: $(BUILD_DIR)/phenoscape-data-kb.ofn

# Monarch data

# Download mgi_slim.ttl
$(BUILD_DIR)/mgi_slim.ttl:
	curl -O https://data.monarchinitiative.org/ttl/mgi_slim.ttl

# Download zfin_slim.ttl
$(BUILD_DIR)/zfin_slim.ttl:
	curl -O https://data.monarchinitiative.org/ttl/zfin_slim.ttl

# Download hpoa.ttl
$(BUILD_DIR)/hpoa.ttl:
	curl -O https://data.monarchinitiative.org/ttl/hpoa.ttl

# Merge monarch data files
$(BUILD_DIR)/monarch-data.ttl: $(BUILD_DIR)/mgi_slim.ttl $(BUILD_DIR)/zfin_slim.ttl $(BUILD_DIR)/hpoa.ttl
	$(ROBOT) merge -i $(BUILD_DIR)/mgi_slim.ttl -i $(BUILD_DIR)/zfin_slim.ttl -i $(BUILD_DIR)/hpoa.ttl -o $@


blah:
	echo $(NEXML_OWLS)
	
#$(wildcard $(BUILD_DIR)/phenoscape-data/curation-files/**/*.xml)

#call phenoscape-kb.sh
kb-init.sh:
	export JAVA_OPTS="-Xmx10G"; \
	export PROJECT_DIR=/Users/shalkishrivastava/renci/Phenoscape/PhenoscapeOwlTools; \
	export TARGET=$$PROJECT_DIR/phenoscape-owl-tools/run/phenoscape-kb; \
	export PIPELINE=$$PROJECT_DIR/phenoscape-owl-tools/pipeline; \
	\
	$$PROJECT_DIR/phenoscape-owl-tools/get_sources.sh; \
	$$PROJECT_DIR/phenoscape-owl-tools/target/universal/stage/bin/kb-owl-tools build-kb $$TARGET $PROJECT_DIR/phenoscape-owl-tools/blazegraph.properties



kb-owlsim-taxa.sh: kb-init.sh
	#${PIPELINE}/kb-owlsim-taxa.sh
	export PROJECT_DIR=/Users/shalkishrivastava/renci/Phenoscape/PhenoscapeOwlTools; \
    export TARGET=$$PROJECT_DIR/phenoscape-owl-tools/run/phenoscape-kbOUTPUT=$$TARGET/owlsim-taxa; \
    \
    mkdir $$OUTPUT; \
    cd $$OUTPUT; \
	\
    export JAVA_OPTS="-Xmx5G"; \
    \
    $$PROJECT_DIR/phenoscape-owl-tools/target/universal/stage/bin/kb-owl-tools pairwise-sim 1 1 $$TARGET/kb/tbox-hierarchy-only.owl $$TARGET/kb/profiles.ttl taxa



kb-owlsim-genes.sh: kb-init.sh
	#${PIPELINE}/kb-owlsim-genes.sh
	export PROJECT_DIR=/Users/shalkishrivastava/renci/Phenoscape/PhenoscapeOwlTools; \
    export TARGET=$$PROJECT_DIR/phenoscape-owl-tools/run/phenoscape-kb; \
    \
    OUTPUT=$$TARGET/owlsim-genes; \
    mkdir $$OUTPUT; \
    cd $$OUTPUT; \
    \
    export JAVA_OPTS="-Xmx5G"; \
    $$PROJECT_DIR/phenoscape-owl-tools/target/universal/stage/bin/kb-owl-tools pairwise-sim 1 1 $$TARGET/kb/tbox-hierarchy-only.owl $$TARGET/kb/profiles.ttl genes



kb-similarity.sh: kb-owlsim-genes.sh kb-owlsim-taxa.sh
	${PIPELINE}/kb-similarity.sh

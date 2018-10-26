#JAVA_OPTS="-Xmx70G"

BUILD_DIR=build
SPARQL=sparql
ROBOT_ENV=ROBOT_JAVA_ARGS=-Xmx12G
ROBOT=$(ROBOT_ENV) robot

all: $(BUILD_DIR)/phenoscape-ontology-classified.ofn

clean:
	rm -rf $(BUILD_DIR)

# Ontologies.ofn - list of ontologies to be imported
# Mirror ontologies locally
$(BUILD_DIR)/mirror: ontologies.ofn
	mkdir -p $(BUILD_DIR) && rm -rf $@ &&\
	$(ROBOT) mirror -i $< -d $@ -o $@/catalog-v001.xml

# Extract ontology metadata
$(BUILD_DIR)/ontology-metadata: ontologies.ofn $(SPARQL)/ontology-versions.sparql
	mkdir -p (BUILD_DIR)/ontology-metadata \
	$(ROBOT) query -i $< --use-graphs true --queries $(SPARQL)/ontology-versions.sparql --output-dir $@


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
$(BUILD_DIR)/qualities.txt: $(BUILD_DIR)/phenoscape-ontology-classified.ofn $(SPARQL)/qualities.sparql
	$(ROBOT) query -i $< --use-graphs true --query $(SPARQL)/qualities.sparql $@

# Extract Anatomical-Entities from ontology
$(BUILD_DIR)/anatomical_entities.txt: $(BUILD_DIR)/phenoscape-ontology-classified.ofn $(SPARQL)/anatomicalEntities.sparql
	$(ROBOT) query -i $< --use-graphs true --query $(SPARQL)/anatomicaEntities.sparql $@

# Create Query-Subsumers
$(BUILD_DIR)/query-subsumers.ofn: $(BUILD_DIR)/qualities.txt $(BUILD_DIR)/anatomical_entities.txt


# Create Similarity-Subsumers
$(BUILD_DIR)/similarity-subsumers.ofn: $(BUILD_DIR)/qualities.txt $(BUILD_DIR)/anatomical_entities.txt

# Download annotated data from Phenex
$(BUILD_DIR)/phenoscape-data:
	git clone https://github.com/phenoscape/phenoscape-data.git $@

# Store paths to all needed NeXML files in NEXMLS variable
NEXMLS = $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/completed-phenex-files -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/fin_limb-incomplete-files -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/Jackson_Dissertation_Files -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/teleost-incomplete-files/Miniature_Monographs -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/teleost-incomplete-files/Miniatures_Matrix_Files -type f -name "*.xml") $(shell find $(BUILD_DIR)/phenoscape-data/curation-files/matrix-vs-monograph -type f -name "*.xml")

# Store paths to all OFN files which will be produced from NeXML files in NEXML_OWLS variable
NEXML_OWLS = $(patsubst %.xml, %.ofn, $(patsubst $(BUILD_DIR)/phenoscape-data/%, $(BUILD_DIR)/phenoscape-data-owl/%, $(NEXMLS)))

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
	$(ROBOT) merge -i $(BUILD_DIR)/phenoscape-data.ofn -i $(BUILD_DIR)/phenoscape-kb-tbox-classified.ofn -o $@


# Generate absences.ttl
$(BUILD_DIR)/absences.ttl: $(BUILD_DIR)/phenoscape-data-kb.ofn $(SPARQL)/absences.sparql
	$(ROBOT) query -i $< --query $(SPARQL)/absences.sparql $@

# Generate presences.ttl
$(BUILD_DIR)/presences.ttl: $(BUILD_DIR)/phenoscape-data-kb.ofn $(SPARQL)/presences.sparql
	$(ROBOT) query -i $< --query $(SPARQL)/presences.sparql $@

# Generate taxon-profiles.ttl
$(BUILD_DIR)/taxon-profiles.ttl: $(BUILD_DIR)/phenoscape-data-kb.ofn $(SPARQL)/taxonProfiles.sparql
	$(ROBOT) query -i $< --query $(SPARQL)/taxonProfiles.sparql $@

# Monarch data

# Download mgi_slim.ttl
$(BUILD_DIR)/mgi_slim.ttl:
	curl -O -L https://data.monarchinitiative.org/ttl/mgi_slim.ttl

# Download zfin_slim.ttl
$(BUILD_DIR)/zfin_slim.ttl:
	curl -O -L https://data.monarchinitiative.org/ttl/zfin_slim.ttl

# Download hpoa.ttl
$(BUILD_DIR)/hpoa.ttl:
	curl -O -L https://data.monarchinitiative.org/ttl/hpoa.ttl

# Merge monarch data files
$(BUILD_DIR)/monarch-data.ttl: $(BUILD_DIR)/mgi_slim.ttl $(BUILD_DIR)/zfin_slim.ttl $(BUILD_DIR)/hpoa.ttl
	$(ROBOT) merge -i $(BUILD_DIR)/mgi_slim.ttl -i $(BUILD_DIR)/zfin_slim.ttl -i $(BUILD_DIR)/hpoa.ttl -o $@

# Generate gene-profiles.ttl
$(BUILD_DIR)/gene-profiles.ttl: $(BUILD_DIR)/monarch-data.ttl $(SPARQL)/geneProfiles.sparql
	$(ROBOT) query -i $< --query $(SPARQL)/geneProfiles.sparql $@

#JAVA_OPTS="-Xmx70G"


BUILD_DIR=build
RESOURCES=resources
SPARQL=sparql
ROBOT_ENV=ROBOT_JAVA_ARGS=-Xmx80G
ROBOT=$(ROBOT_ENV) robot
JVM_ARGS=JVM_ARGS=-Xmx80G
ARQ=$(JVM_ARGS) arq
RIOT=riot
BLAZEGRAPH-RUNNER=JAVA_OPTS=-Xmx80G blazegraph-runner

BIO-ONTOLOGIES=ontologies.ofn
# Path to data repo; must be separately downloaded/cloned
NEXML_DATA=phenoscape-data
NEXML_SUBDIRS_FILE=nexml-subdirs.txt
DB_FILE=$(BUILD_DIR)/blazegraph-loaded-all.jnl
BLAZEGRAPH_PROPERTIES=$(RESOURCES)/blazegraph.properties
MONARCH=https://data.monarchinitiative.org/dev



# ---------------------------------------------------------------------

clean:
	rm -rf $(BUILD_DIR)


# ########## # ##########
# ########## # ##########

# Modules:
# 1. KB build
# 2. Semantic similarity


all: kb-build $(DB_FILE)

# ########## # ##########
# ########## # ##########


# ********** * **********


# ########## # ##########
# ########## # ##########

# Module 1 ---> KB build

# ########## # ##########

# Products
# 1. Phenoscape KB
# 2. Phenoscape KB TBox Hierarchy


kb-build: $(BUILD_DIR)/phenoscape-kb.ttl $(BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ttl

# ########## # ##########


# ##########
# 1. Phenoscape KB

$(BUILD_DIR)/phenoscape-kb.ttl: $(BUILD_DIR)/ontology-metadata.ttl $(BUILD_DIR)/phenex-data+tbox.ttl $(BUILD_DIR)/monarch-data-merged.ttl $(BUILD_DIR)/gene-profiles.ttl $(BUILD_DIR)/absences.ttl $(BUILD_DIR)/presences.ttl $(BUILD_DIR)/evolutionary-profiles.ttl
	$(RIOT) --verbose --nocheck --output=NTRIPLES \
	$(BUILD_DIR)/ontology-metadata.ttl \
	$(BUILD_DIR)/phenex-data+tbox.ttl \
	$(BUILD_DIR)/monarch-data-merged.ttl \
	$(BUILD_DIR)/gene-profiles.ttl \
	$(BUILD_DIR)/absences.ttl \
	$(BUILD_DIR)/presences.ttl \
	$(BUILD_DIR)/evolutionary-profiles.ttl \
	> $@.tmp && mv $@.tmp $@


# ----------

# 2. Phenoscape KB TBox Hierarchy

# Compute Tbox hierarchy
$(BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ttl: $(BUILD_DIR)/phenoscape-kb-tbox-classified.ttl $(SPARQL)/subclassHierarchy.sparql
	$(ARQ) -q --data=$< --query=$(SPARQL)/subclassHierarchy.sparql --results=ttl > $@.tmp \
	&& mv $@.tmp $@

# ##########


# ##########
# Component 1 --> Imported bio-ontologies' metadata

# Extract ontology metadata
# ## Query for ontologies' version information
$(BUILD_DIR)/ontology-metadata.ttl: $(BIO-ONTOLOGIES) $(BUILD_DIR)/mirror $(SPARQL)/ontology-versions.sparql
	$(ROBOT) query \
	--catalog $(BUILD_DIR)/mirror/catalog-v001.xml \
	-i $< \
	--use-graphs true \
	--format ttl \
	--query $(SPARQL)/ontology-versions.sparql $@.tmp \
	&& mv $@.tmp $@

# ----------

# Mirror ontologies locally
# $(ONTOLOGIES) - list of ontologies to be imported
$(BUILD_DIR)/mirror: $(BIO-ONTOLOGIES)
	rm -rf $@ ; \
	$(ROBOT) mirror -i $< -d $@ -o $@/catalog-v001.xml

# ##########


# ##########
# Component 2 --> Phenex data + TBox

# Create Phenex data + TBox KB
$(BUILD_DIR)/phenex-data+tbox.ttl: $(BUILD_DIR)/phenex-data-merged.ofn $(BUILD_DIR)/phenoscape-kb-tbox-classified.ttl
	$(ROBOT) merge \
    	-i $(BUILD_DIR)/phenex-data-merged.ofn \
    	-i $(BUILD_DIR)/phenoscape-kb-tbox-classified.ttl \
    	convert --format ttl \
    	-o $@.tmp \
    	&& mv $@.tmp $@

# ----------

# Store paths to all needed Phenex NeXML files in NEXMLS variable
NEXML_SUBDIRS := $(addprefix ${NEXML_DATA}/, $(shell cat ${NEXML_SUBDIRS_FILE}))
NEXMLS := $(shell find $(NEXML_SUBDIRS) -type f -name "*.xml")

# Store paths to all OFN files which will be produced from NeXML files in NEXML_OWLS variable
NEXML_OWLS := $(patsubst %.xml, %.ofn, $(patsubst $(NEXML_DATA)/%, $(BUILD_DIR)/phenex-data-owl/%, $(NEXMLS)))

# Convert a single NeXML file to its counterpart OFN
$(BUILD_DIR)/phenex-data-owl/%.ofn: $(NEXML_DATA)/%.xml $(BUILD_DIR)/bio-ontologies-merged.ttl
	mkdir -p $(dir $@) \
	&& kb-owl-tools convert-nexml $(BUILD_DIR)/bio-ontologies-merged.ttl $< $@.tmp \
	&& mv $@.tmp $@


# Generate phenex-data-merged.ofn

# Merge all Phenex NeXML OFN files into a single ontology of phenotype annotations
$(BUILD_DIR)/phenex-data-merged.ofn: $(NEXML_OWLS)
	$(ROBOT) merge $(addprefix -i , $(NEXML_OWLS)) \
	convert --format ofn \
	-o $@.tmp \
	&& mv $@.tmp $@

# ----------

# Generate phenoscape-kb-tbox-classified.ofn

# Compute final inferred classification of Phenoscape KB Tbox
$(BUILD_DIR)/phenoscape-kb-tbox-classified.ttl: $(BUILD_DIR)/phenoscape-kb-tbox-classified-plus-absence.ttl
	$(ROBOT) reason \
	--reasoner ELK \
	--axiom-generators "SubClass EquivalentClass" \
	--exclude-duplicate-axioms true \
	--exclude-tautologies structural \
	--i $< \
	convert --format ttl \
	-o $@.tmp \
	&& mv $@.tmp $@

# Generate phenoscape-kb-tbox-classified-plus-absence.ttl
$(BUILD_DIR)/phenoscape-kb-tbox-classified-plus-absence.ttl: $(BUILD_DIR)/phenoscape-kb-tbox-classified-pre-absence-reasoning.ofn $(BUILD_DIR)/negation-hierarchy.ofn
	$(ROBOT) merge \
	-i $(BUILD_DIR)/phenoscape-kb-tbox-classified-pre-absence-reasoning.ofn \
	-i $(BUILD_DIR)/negation-hierarchy.ofn \
	convert --format ttl \
	-o $@.tmp \
	&& mv $@.tmp $@

# ----------

# Generate negation-hierarchy.ofn
$(BUILD_DIR)/negation-hierarchy.ofn: $(BUILD_DIR)/phenoscape-kb-tbox-classified-pre-absence-reasoning.ofn
	kb-owl-tools assert-negation-hierarchy $< $@.tmp \
	&& mv $@.tmp $@

# ----------

# Generate phenoscape-kb-tbox-classified-pre-absence-reasoning.ofn
$(BUILD_DIR)/phenoscape-kb-tbox-classified-pre-absence-reasoning.ofn: $(BUILD_DIR)/phenoscape-kb-tbox.ofn
	$(ROBOT) reason \
	-i $< \
	--reasoner ELK \
	--axiom-generators "SubClass EquivalentClass" \
	--exclude-duplicate-axioms true \
	--exclude-tautologies structural \
	convert --format ofn \
	-o $@.tmp \
	&& mv $@.tmp $@

# ----------

$(BUILD_DIR)/bio-ontologies-merged-expanded-entities.ttl: $(BUILD_DIR)/bio-ontologies-classified.ttl \
$(BUILD_DIR)/anatomical-entity/part_of.ofn \
$(BUILD_DIR)/anatomical-entity/develops_from.ofn
	$(ROBOT) merge \
	$(addprefix -i ,$^) \
	reason --reasoner ELK \
	--exclude-duplicate-axioms true \
	--exclude-tautologies structural \
	convert --format ofn \
	-o $@.tmp \
	&& mv $@.tmp $@

# Generate phenoscape-kb-tbox.ofn
$(BUILD_DIR)/phenoscape-kb-tbox.ofn: $(BUILD_DIR)/bio-ontologies-classified.ttl \
$(BUILD_DIR)/defined-by-links.ttl \
$(BUILD_DIR)/phenex-tbox.ofn \
$(BUILD_DIR)/anatomical-entity-implies_presence_of.ofn \
$(BUILD_DIR)/anatomical-entity-absences.ofn \
$(BUILD_DIR)/anatomical-entity/part_of.ofn \
$(BUILD_DIR)/anatomical-entity/develops_from.ofn \
$(BUILD_DIR)/phenotype/phenotype_of_anatomical_entity.ofn \
$(BUILD_DIR)/phenotype/phenotype_of_quality.ofn
	$(ROBOT) merge \
	$(addprefix -i ,$^) \
    convert --format ofn \
	-o $@.tmp \
	&& mv $@.tmp $@

# ----------

# *** Subsumers ***

# -----

$(BUILD_DIR)/defined-by-links.ttl: $(BUILD_DIR)/bio-ontologies-merged.ttl $(SPARQL)/isDefinedBy.sparql
	$(ROBOT) query \
	--use-graphs true \
	--format ttl \
	--input $< \
	--query $(SPARQL)/isDefinedBy.sparql $@

$(BUILD_DIR)/anatomical-entity/%.ofn: patterns/anatomical-entity/%.yaml $(BUILD_DIR)/core-anatomical-entities.txt $(BUILD_DIR)/bio-ontologies-merged.ttl
	mkdir -p $(BUILD_DIR)/anatomical-entity &&\
	dosdp-tools generate \
		--generate-defined-class=true \
		--obo-prefixes=true \
		--ontology=$(BUILD_DIR)/bio-ontologies-merged.ttl \
		--template=$< \
		--infile=$(BUILD_DIR)/core-anatomical-entities.txt \
		--outfile=$@.tmp &&\
	mv $@.tmp $@

$(BUILD_DIR)/phenotype/phenotype_of_anatomical_entity.ofn: patterns/phenotype/phenotype_of_anatomical_entity.yaml $(BUILD_DIR)/expanded-anatomical-entities.txt $(BUILD_DIR)/bio-ontologies-merged-expanded-entities.ttl
	mkdir -p $(BUILD_DIR)/phenotype &&\
	dosdp-tools generate \
		--generate-defined-class=true \
		--obo-prefixes=true \
		--ontology=$(BUILD_DIR)/bio-ontologies-merged-expanded-entities.ttl \
		--template=$< \
		--infile=$(BUILD_DIR)/expanded-anatomical-entities.txt \
		--outfile=$@.tmp &&\
	mv $@.tmp $@

$(BUILD_DIR)/phenotype/phenotype_of_quality.ofn: patterns/phenotype/phenotype_of_quality.yaml $(BUILD_DIR)/qualities.txt $(BUILD_DIR)/bio-ontologies-merged.ttl
	mkdir -p $(BUILD_DIR)/phenotype &&\
	dosdp-tools generate \
		--generate-defined-class=true \
		--obo-prefixes=true \
		--ontology=$(BUILD_DIR)/bio-ontologies-merged.ttl \
		--template=$< \
		--infile=$(BUILD_DIR)/qualities.txt \
		--outfile=$@.tmp &&\
	mv $@.tmp $@


$(BUILD_DIR)/anatomical-entity-%.ofn: patterns/%.yaml $(BUILD_DIR)/core-anatomical-entities.txt $(BUILD_DIR)/bio-ontologies-merged.ttl
	mkdir -p $(dir $@) \
    	&& dosdp-tools generate \
    	--generate-defined-class=true \
    	--obo-prefixes=true \
    	--ontology=$(BUILD_DIR)/bio-ontologies-merged.ttl \
	--template=$< \
	--infile=$(BUILD_DIR)/core-anatomical-entities.txt \
    	--outfile=$@.tmp \
    	&& mv $@.tmp $@

# -----

# Generate anatomical-entities.txt
$(BUILD_DIR)/core-anatomical-entities.txt: $(BUILD_DIR)/bio-ontologies-classified.ttl $(SPARQL)/anatomicalEntities.sparql
	$(ARQ) \
		-q \
    	--data=$< \
    	--data=$(BUILD_DIR)/defined-by-links.ttl \
    	--results=TSV \
    	--query=$(SPARQL)/anatomicalEntities.sparql > $@.tmp \
	&& sed 's/^\?//' $@.tmp > $@.tmp2 \
	&& rm $@.tmp && mv $@.tmp2 $@

$(BUILD_DIR)/expanded-anatomical-entities.txt: $(BUILD_DIR)/bio-ontologies-merged-expanded-entities.ttl $(SPARQL)/anatomicalEntities.sparql
	$(ARQ) \
		-q \
    	--data=$< \
    	--data=$(BUILD_DIR)/defined-by-links.ttl \
    	--results=TSV \
    	--query=$(SPARQL)/anatomicalEntities.sparql > $@.tmp \
	&& sed 's/^\?//' $@.tmp > $@.tmp2 \
	&& rm $@.tmp && mv $@.tmp2 $@

# Generate qualities.txt
$(BUILD_DIR)/qualities.txt: $(BUILD_DIR)/bio-ontologies-classified.ttl $(SPARQL)/qualities.sparql
	$(ROBOT) query \
    	-i $< \
    	--use-graphs true \
    	--query $(SPARQL)/qualities.sparql $@.tmp \
    	&& mv $@.tmp $@

# -----

# ----------

# Generate bio-ontologies-classified.ttl
# Compute inferred classification of just the input ontologies.
# We need to remove axioms that can infer unsatisfiability, since
# the input ontologies are not 100% compatible.
$(BUILD_DIR)/bio-ontologies-classified.ttl: $(BUILD_DIR)/bio-ontologies-merged.ttl
	$(ROBOT) remove -i $< --axioms 'disjoint' --trim true \
	remove --term 'owl:Nothing' --trim true \
	reason \
	--reasoner ELK \
	--axiom-generators "SubClass EquivalentClass" \
	--exclude-duplicate-axioms true \
	--exclude-tautologies structural \
	convert --format ttl \
	-o $@.tmp \
	&& mv $@.tmp $@

# Merge imported ontologies
# Remove root ZP phenotype because it attracts anything related to 'abnormal' (sizes) during semantic similarity calculations
$(BUILD_DIR)/bio-ontologies-merged.ttl: $(BIO-ONTOLOGIES) mod_taxa.ttl $(BUILD_DIR)/mirror $(SPARQL)/update_zfa_labels.ru $(SPARQL)/update_xao_labels.ru 
	$(ROBOT) merge \
	--catalog $(BUILD_DIR)/mirror/catalog-v001.xml \
	-i $< \
	-i mod_taxa.ttl \
	query \
	--update $(SPARQL)/update_zfa_labels.ru \
	--update $(SPARQL)/update_xao_labels.ru \
	remove --term 'ZP:00000000' --trim true \
	convert --format ttl \
	-o $@.tmp \
	&& mv $@.tmp $@

# ----------

# Generate phenex-tbox.ofn
# Remove abox axioms from phenex-data-merged.ofn
$(BUILD_DIR)/phenex-tbox.ofn: $(BUILD_DIR)/phenex-data-merged.ofn
	$(ROBOT) remove \
	-i $< \
	--axioms abox \
	convert --format ofn \
	-o $@.tmp \
	&& mv $@.tmp $@

# ----------

# ##########


# ##########
# Component 3 ---> Monarch data

# Monarch data
# 1. MGI
# 2. ZFIN

# Merge monarch data files
$(BUILD_DIR)/monarch-data-merged.ttl: $(BUILD_DIR)/monarch/mgislim.ttl $(BUILD_DIR)/monarch/zfinslim.ttl $(BUILD_DIR)/monarch-types-labels.ttl
	$(ROBOT) merge \
	-i $(BUILD_DIR)/monarch/mgislim.ttl \
	-i $(BUILD_DIR)/monarch/zfinslim.ttl \
	-i $(BUILD_DIR)/monarch-types-labels.ttl \
	convert --format ttl \
	-o $@.tmp \
	&& mv $@.tmp $@

# Query monarch data for types and labels
$(BUILD_DIR)/monarch-types-labels.ttl: $(SPARQL)/monarch-types-labels.sparql $(BUILD_DIR)/monarch/mgi.ttl $(BUILD_DIR)/monarch/zfin.ttl
	$(ARQ) \
	-q \
	--data=$(BUILD_DIR)/monarch/mgi.ttl \
	--data=$(BUILD_DIR)/monarch/zfin.ttl \
	--query=$< \
	--results=NTRIPLES > $@.tmp \
	&& mv $@.tmp $@


# Download MONARCH files
$(BUILD_DIR)/monarch/%:
	mkdir -p $(BUILD_DIR)/monarch
	curl -L $(MONARCH)/$* -o $@.tmp \
	&& mv $@.tmp $@


# ##########


# ##########
# Component 4 ----> Profiles

# Generate gene-profiles.ttl
$(BUILD_DIR)/gene-profiles.ttl: $(BUILD_DIR)/monarch-data-merged.ttl $(SPARQL)/geneProfiles.sparql
	$(ROBOT) query \
    	-i $< \
    	--format ttl \
    	--query $(SPARQL)/geneProfiles.sparql $@.tmp \
    	&& mv $@.tmp $@

# Generate absences.ttl
$(BUILD_DIR)/absences.ttl: $(SPARQL)/absences.sparql $(BUILD_DIR)/subclass-closure.ttl  $(BUILD_DIR)/phenex-data+tbox.ttl 
	$(ARQ) \
	-q \
	--data=$(BUILD_DIR)/phenex-data+tbox.ttl \
	--data=$(BUILD_DIR)/subclass-closure.ttl \
	--results=TSV \
	--query=$< > $@.tmp \
	&& sed -e '1d' -e 's/$$/ ./' $@.tmp > $@.tmp2 \
	&& rm $@.tmp && mv $@.tmp2 $@
	

# Generate presences.ttl
$(BUILD_DIR)/presences.ttl: $(SPARQL)/presences.sparql $(BUILD_DIR)/subclass-closure.ttl $(BUILD_DIR)/phenex-data+tbox.ttl
	$(ARQ) \
	-q \
	--data=$(BUILD_DIR)/phenex-data+tbox.ttl \
	--data=$(BUILD_DIR)/subclass-closure.ttl \
	--results=TSV \
	--query=$< > $@.tmp \
	&& sed -e '1d' -e 's/$$/ ./' $@.tmp > $@.tmp2 \
	&& rm $@.tmp && mv $@.tmp2 $@



# Generate evolutionary-profiles.ttl
# Contains taxon-profiles data
$(BUILD_DIR)/evolutionary-profiles.ttl: $(BUILD_DIR)/phenex-data+tbox.ttl
	kb-owl-tools output-evolutionary-profiles $< $@.tmp \
	&& mv $@.tmp $@


# ##########



# ##########
# Component 5 ----> Closures

# Compute subclass closures
$(BUILD_DIR)/subclass-closure.ttl: $(BUILD_DIR)/phenoscape-kb-tbox-classified.ttl $(SPARQL)/subclass-closure-construct.sparql
	$(ARQ) \
	-q \
	--data=$< \
	--optimize=off \
	--results=TSV \
	--query=$(SPARQL)/subclass-closure-construct.sparql > $@.tmp \
	&& sed -e '1d' -e 's/$$/ ./' $@.tmp > $@.tmp2 \
	&& rm $@.tmp && mv $@.tmp2 $@


# Compute instance closures
$(BUILD_DIR)/instance-closure.ttl: $(SPARQL)/profile-instance-closure-construct.sparql $(BUILD_DIR)/phenex-data+tbox.ttl $(BUILD_DIR)/gene-profiles.ttl $(BUILD_DIR)/evolutionary-profiles.ttl
	$(ARQ) \
	-q \
	--data=$(BUILD_DIR)/phenex-data+tbox.ttl \
	--data=$(BUILD_DIR)/gene-profiles.ttl \
	--data=$(BUILD_DIR)/evolutionary-profiles.ttl \
	--results=NTRIPLES \
	--query=$< > $@.tmp \
	&& mv $@.tmp $@


$(BUILD_DIR)/phylopics.owl: $(NEXML_DATA)/KB_static_data/phylopics.owl
	cp $< $@

$(BUILD_DIR)/vto_ncbi_common_names.owl: $(NEXML_DATA)/KB_static_data/vto_ncbi_common_names.owl
	cp $< $@


# ########## # ##########
# ########## # ##########


# ##########
# Load pipeline artifacts into Blazegraph database

# Artifacts:
# 1. Phenoscape KB
# 2. Closures = subclass + instance)
# 3. taxa-sim = taxa-ics + taxa-expect-scores + taxa-pairwise-sim
# 4. gene-sim = gene-ics + gene-expect-scores + gene-pairwise-sim
# 5. build-time

# Insert KB build time in DB
$(BUILD_DIR)/build-time.ttl: $(SPARQL)/build-time.sparql
	echo "<http://kb.phenoscape.org/> <http://www.w3.org/2000/01/rdf-schema#label> \"Phenoscape Knowledgebase\" ." > $(BUILD_DIR)/kb-label.ttl && \
	$(ARQ) \
	-q \
	--data=$(BUILD_DIR)/kb-label.ttl \
	--results=NTRIPLES \
	--query=$< > $@.tmp \
	&& mv $@.tmp $@

$(DB_FILE): $(BLAZEGRAPH_PROPERTIES) \
			$(BUILD_DIR)/phenoscape-kb.ttl \
			$(BUILD_DIR)/subclass-closure.ttl $(BUILD_DIR)/instance-closure.ttl \
			$(BUILD_DIR)/phylopics.owl \
			$(BUILD_DIR)/vto_ncbi_common_names.owl \
			$(BUILD_DIR)/build-time.ttl
	rm -f $@ && \
 	$(BLAZEGRAPH-RUNNER) load --informat=turtle --journal=$@ --properties=$< --graph="http://kb.phenoscape.org/" $(BUILD_DIR)/phenoscape-kb.ttl && \
 	$(BLAZEGRAPH-RUNNER) load --informat=turtle --journal=$@ --properties=$< --graph="http://kb.phenoscape.org/closure" $(BUILD_DIR)/subclass-closure.ttl && \
 	$(BLAZEGRAPH-RUNNER) load --informat=turtle --journal=$@ --properties=$< --graph="http://kb.phenoscape.org/closure" $(BUILD_DIR)/instance-closure.ttl && \
 	$(BLAZEGRAPH-RUNNER) load --informat=rdfxml --journal=$@ --properties=$< --graph="http://purl.org/phenoscape/phylopics.owl" $(BUILD_DIR)/phylopics.owl && \
	$(BLAZEGRAPH-RUNNER) load --informat=rdfxml --journal=$@ --properties=$< --graph="http://kb.phenoscape.org/" $(BUILD_DIR)/vto_ncbi_common_names.owl && \
 	$(BLAZEGRAPH-RUNNER) load --informat=turtle --journal=$@ --properties=$< --graph="http://kb.phenoscape.org/" $(BUILD_DIR)/build-time.ttl

# ##########

# ########## # ##########
# ########## # ##########


# ########## # ########## # ########## # THE END # ########## # ########## # ########## #

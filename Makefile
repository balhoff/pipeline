#JAVA_OPTS="-Xmx70G"


BUILD_DIR=build
RESOURCES=resources
SPARQL=sparql
ROBOT_ENV=ROBOT_JAVA_ARGS=-Xmx128G
ROBOT=$(ROBOT_ENV) robot

ONTOLOGIES=ontologies.ofn
# Path to data repo; must be separately downloaded/cloned
NEXML_DATA=phenoscape-data

all: $(BUILD_DIR)/phenoscape-kb.ttl $(BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ofn $(BUILD_DIR)/qualities.txt $(BUILD_DIR)/anatomical_entities.txt

clean:
	rm -rf $(BUILD_DIR)

# $(ONTOLOGIES) - list of ontologies to be imported
# Mirror ontologies locally
$(BUILD_DIR)/mirror: $(ONTOLOGIES)
	rm -rf $@ ; \
	$(ROBOT) mirror -i $< -d $@ -o $@/catalog-v001.xml

# Extract ontology metadata
$(BUILD_DIR)/ontology-versions.ttl: $(ONTOLOGIES) $(SPARQL)/ontology-versions.sparql
	$(ROBOT) query -i $< --use-graphs true --query $(SPARQL)/ontology-versions.sparql $@

# Merge imported ontologies
$(BUILD_DIR)/phenoscape-ontology.ofn: $(ONTOLOGIES) $(BUILD_DIR)/mirror
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
	$(ROBOT) query -i $< --use-graphs true --query $(SPARQL)/anatomicalEntities.sparql $@

# Absence reasoning
$(BUILD_DIR)/anatomical_entity_parts.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/part_of.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/part_of.yaml --infile=$(BUILD_DIR)/anatomical_entities.txt --outfile=$@


$(BUILD_DIR)/anatomical-entity-hasParts.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/has_part.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/has_part.yaml --infile=$(BUILD_DIR)/anatomical_entities.txt --outfile=$@


$(BUILD_DIR)/anatomical-entity-presences.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/implies_presence_of.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/implies_presence_of.yaml --infile=$(BUILD_DIR)/anatomical_entities.txt --outfile=$@


$(BUILD_DIR)/anatomical-entity-absences.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/absences.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/absences.yaml --infile=$(BUILD_DIR)/anatomical_entities.txt --outfile=$@


$(BUILD_DIR)/anatomical-entity-hasPartsInheringIns.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/has_part_inhering_in.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/has_part_inhering_in.yaml --infile=$(BUILD_DIR)/anatomical_entities.txt --outfile=$@


$(BUILD_DIR)/anatomical-entity-phenotypeOfs.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/phenotype_of.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/phenotype_of.yaml --infile=$(BUILD_DIR)/anatomical_entities.txt --outfile=$@


$(BUILD_DIR)/anatomical-entity-namedHasPartClasses.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/named_has_part.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/named_has_part.yaml --infile=$(BUILD_DIR)/anatomical_entities.txt --outfile=$@


$(BUILD_DIR)/developsFromRulesForAbsence.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/develops_from_rule.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/develops_from_rule.yaml --infile=$< --outfile=$@


# Create Similarity-Subsumers
$(BUILD_DIR)/anatomical-entity-phenotypeOf-partOf.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/phenotype_of_part_of.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/phenotype_of_part_of.yaml --infile=$< --outfile=$@

$(BUILD_DIR)/anatomical-entity-phenotypeOf-developsFrom.ofn: $(BUILD_DIR)/anatomical_entities.txt patterns/phenotype_of_develops_from.yaml
	mkdir -p $(dir $@) && dosdp-tools generate --generate-defined-class=true --obo-prefixes=true --template=patterns/phenotype_of_develops_from.yaml --infile=$< --outfile=$@

# Store paths to all needed NeXML files in NEXMLS variable
NEXMLS := $(shell mkdir -p $(BUILD_DIR); find $(NEXML_DATA)/curation-files/completed-phenex-files -type f -name "*.xml") \
$(shell find $(NEXML_DATA)/curation-files/fin_limb-incomplete-files -type f -name "*.xml") \
$(shell find $(NEXML_DATA)/curation-files/Jackson_Dissertation_Files -type f -name "*.xml") \
$(shell find $(NEXML_DATA)/curation-files/teleost-incomplete-files/Miniature_Monographs -type f -name "*.xml") \
$(shell find $(NEXML_DATA)/curation-files/teleost-incomplete-files/Miniatures_Matrix_Files -type f -name "*.xml") \
$(shell find $(NEXML_DATA)/curation-files/matrix-vs-monograph -type f -name "*.xml")

# Store paths to all OFN files which will be produced from NeXML files in NEXML_OWLS variable
NEXML_OWLS := $(patsubst %.xml, %.ofn, $(patsubst $(NEXML_DATA)/%, $(BUILD_DIR)/phenoscape-data-owl/%, $(NEXMLS)))

# Convert a single NeXML file to its counterpart OFN
$(BUILD_DIR)/phenoscape-data-owl/%.ofn: $(NEXML_DATA)/%.xml $(BUILD_DIR)/phenoscape-ontology.ofn
	mkdir -p $(dir $@)
	kb-owl-tools convert-nexml $(BUILD_DIR)/phenoscape-ontology.ofn $< $@

# Merge all NeXML OFN files into a single ontology of phenotype annotations
$(BUILD_DIR)/phenoscape-data.ofn: $(NEXML_OWLS)
	$(ROBOT) merge $(addprefix -i , $(NEXML_OWLS)) -o $@

# Extract tbox and rbox from phenoscape-data.ofn
$(BUILD_DIR)/phenoscape-data-tbox.ofn: $(BUILD_DIR)/phenoscape-data.ofn
	$(ROBOT) filter -i $< --axioms tbox --axioms rbox -o $@

# Create Phenoscape KB Tbox
$(BUILD_DIR)/phenoscape-kb-tbox.ofn: $(BUILD_DIR)/phenoscape-data-tbox.ofn $(BUILD_DIR)/phenoscape-ontology-classified.ofn $(BUILD_DIR)/anatomical-entity-phenotypeOf-partOf.ofn $(BUILD_DIR)/anatomical-entity-phenotypeOf-developsFrom.ofn
	$(ROBOT) merge -i $< \
	-i $(BUILD_DIR)/phenoscape-ontology-classified.ofn \
	-i $(BUILD_DIR)/anatomical-entity-phenotypeOf-partOf.ofn \
	-i $(BUILD_DIR)/anatomical-entity-phenotypeOf-developsFrom.ofn \
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
	mkdir -p $(BUILD_DIR)
	curl -L https://data.monarchinitiative.org/ttl/mgi_slim.ttl -o $@

# Download zfinslim.ttl
$(BUILD_DIR)/zfinslim.ttl:
	mkdir -p $(BUILD_DIR)
	curl -L https://data.monarchinitiative.org/ttl/zfinslim.ttl -o $@

# Download hpoa.ttl
$(BUILD_DIR)/hpoa.ttl:
	mkdir -p $(BUILD_DIR)
	curl -L https://data.monarchinitiative.org/ttl/hpoa.ttl -o $@

# Merge monarch data files
$(BUILD_DIR)/monarch-data.ttl: $(BUILD_DIR)/mgi_slim.ttl $(BUILD_DIR)/zfinslim.ttl $(BUILD_DIR)/hpoa.ttl
	$(ROBOT) merge -i $(BUILD_DIR)/mgi_slim.ttl -i $(BUILD_DIR)/zfinslim.ttl -i $(BUILD_DIR)/hpoa.ttl -o $@

# Generate gene-profiles.ttl
$(BUILD_DIR)/gene-profiles.ttl: $(BUILD_DIR)/monarch-data.ttl $(SPARQL)/geneProfiles.sparql
	$(ROBOT) query -i $< --query $(SPARQL)/geneProfiles.sparql $@

#Create Phenoscape KB
$(BUILD_DIR)/phenoscape-kb.ttl: $(BUILD_DIR)/gene-profiles.ttl $(BUILD_DIR)/absences.ttl $(BUILD_DIR)/presences.ttl $(BUILD_DIR)/taxon-profiles.ttl $(BUILD_DIR)/monarch-data.ttl $(BUILD_DIR)/ontology-versions.ttl
	$(ROBOT) merge  -i $(BUILD_DIR)/gene-profiles.ttl -i $(BUILD_DIR)/absences.ttl -i $(BUILD_DIR)/presences.ttl -i $(BUILD_DIR)/taxon-profiles.ttl -i $(BUILD_DIR)/monarch-data.ttl -i $(BUILD_DIR)/ontology-versions.ttl -o $@


# Generate profiles.ttl for genes and taxa
$(BUILD_DIR)/profiles.ttl: $(BUILD_DIR)/taxon-profiles.ttl $(BUILD_DIR)/gene-profiles.ttl
	$(ROBOT) merge -i $(BUILD_DIR)/taxon-profiles.ttl -i $(BUILD_DIR)/gene-profiles.ttl -o $@

# Pairwise similarity for genes and taxa
$(BUILD_DIR)/gene-pairwise-sim.ttl: $(BUILD_DIR)/profiles.ttl
	kb-owl-tools pairwise-sim 1 1 (BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ofn $< genes $@

$(BUILD_DIR)/taxa-pairwise-sim.ttl: $(BUILD_DIR)/profiles.ttl
	kb-owl-tools pairwise-sim 1 1 (BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ofn $< taxa $@


# Querying subclass closure
$(BUILD_DIR)/subclass-closure.ttl: $(BUILD_DIR)/phenoscape-kb.ttl $(SPARQL)/subclass-closure-construct.sparql
	sparql --data=$< --query=$(SPARQL)/subclass-closure-construct.sparql > $@


# Querying profile instance closure
$(BUILD_DIR)/instance-closure.ttl: $(BUILD_DIR)/phenoscape-kb.ttl $(SPARQL)/profile-instance-closure-construct.sparql
	sparql --data=$< --query=$(SPARQL)/profile-instance-closure-construct.sparql > $@


# Outputting ICs

$(BUILD_DIR)/corpus-ics-taxa.ttl: $(BUILD_DIR)/profiles.ttl $(BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ofn
	kb-owl-tools output-ics $(BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ofn $< taxa $@

$(BUILD_DIR)/corpus-ics-genes.ttl: $(BUILD_DIR)/profiles.ttl $(BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ofn
	kb-owl-tools output-ics $(BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ofn $< genes $@


# Output profile sizes
$(BUILD_DIR)/profiles-sizes.txt: $(BUILD_DIR)/phenoscape-kb-tbox-hierarchy.ofn$(BUILD_DIR)/profiles.ttl
	kb-owl-tools output-profile-sizes $< $(BUILD_DIR)/profiles.ttl $@


# Generate expect scores for taxa and genes

# taxa-expect-scores

$(BUILD_DIR)/taxa-scores.tsv: $(RESOURCES)/get-scores.rq $(BUILD_DIR)/corpus-ics-taxa.ttl
	sparql --data=$(BUILD_DIR)/corpus-ics-taxa.ttl --query=$< --results=TSV > $@

$(BUILD_DIR)/taxa-rank-statistics.txt: $(RESOURCES)/regression.py $(BUILD_DIR)/profile-sizes.txt $(BUILD_DIR)/taxa-scores.tsv
	python $< `grep -v 'VTO_' $(BUILD_DIR)/profile-sizes.txt | wc -l` $(BUILD_DIR)/taxa-scores.tsv $@

(BUILD_DIR)/taxa-expect-scores.ttl: $(BUILD_DIR)/taxa-rank-statistics.txt
	kb-owl-tools expects-to-triples $< $@


# gene-expect-scores

$(BUILD_DIR)/gene-scores.tsv: $(RESOURCES)/get-scores.rq $(BUILD_DIR)/corpus-ics-genes.ttl
	sparql --data=$(BUILD_DIR)/corpus-ics-genes.ttl --query=$< --results=TSV > $@

$(BUILD_DIR)/gene-rank-statistics.txt: $(RESOURCES)/regression.py $(BUILD_DIR)/profile-sizes.txt $(BUILD_DIR)/gene-scores.tsv
	python $< `grep -v 'VTO_' $(BUILD_DIR)/profile-sizes.txt | wc -l` $(BUILD_DIR)/gene-scores.tsv $@

(BUILD_DIR)/gene-expect-scores.ttl: $(BUILD_DIR)/gene-rank-statistics.txt
	kb-owl-tools expects-to-triples $< $@
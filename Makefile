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

$(BUILD_DIR)/mirror: ontologies.ofn
	mkdir -p $(BUILD_DIR) && rm -rf $@ &&\
	$(ROBOT) mirror -i $< -d $@ -o $@/catalog-v001.xml

$(BUILD_DIR)/phenoscape-ontology.ofn: ontologies.ofn $(BUILD_DIR)/mirror
	$(ROBOT) merge --catalog $(BUILD_DIR)/mirror/catalog-v001.xml -i $< -o $@

$(BUILD_DIR)/phenoscape-ontology-classified.ofn: $(BUILD_DIR)/phenoscape-ontology.ofn
	$(ROBOT) remove -i $< --axioms 'disjoint' --trim true \
	remove --term 'owl:Nothing' --trim true \
	reason --reasoner ELK -o $@



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

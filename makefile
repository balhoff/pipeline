#JAVA_OPTS="-Xmx70G"
#TARGET=/scratch/balhoff/phenoscape-kb
#get KB sources
#KB_SOURCES: get_sources.sh
#	$HOME/phenoscape-owl-tools/get_sources.sh
#building KB
#semantic similarity processing
#BUILD_KB: KB_SOURCES
#	$HOME/phenoscape-owl-tools/target/universal/stage/bin/kb-owl-tools build-kb $TARGET $HOME/phenoscape-owl-tools/blazegraph.properties

PROJECT_DIR=/Users/shalkishrivastava/renci/Phenoscape/PhenoscapeOwlTools
TARGET=${PROJECT_DIR}/phenoscape-owl-tools/run/phenoscape-kb
PIPELINE=${PROJECT_DIR}/phenoscape-owl-tools/pipeline

#call phenoscape-kb.sh
all:
	${PIPELINE}/kb-init.sh
	${PIPELINE}/kb-owlsim-taxa.sh
	${PIPELINE}/kb-owlsim-genes.sh
	${PIPELINE}/kb-similarity.sh
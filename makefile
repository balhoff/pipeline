#JAVA_OPTS="-Xmx70G"
#TARGET=/scratch/balhoff/phenoscape-kb
#get KB sources
#KB_SOURCES: get_sources.sh
#	$HOME/phenoscape-owl-tools/get_sources.sh
#building KB
#semantic similarity processing
#BUILD_KB: KB_SOURCES
#	$HOME/phenoscape-owl-tools/target/universal/stage/bin/kb-owl-tools build-kb $TARGET $HOME/phenoscape-owl-tools/blazegraph.properties

#call phenoscape-kb.sh
all:
	~/renci/Phenoscape/PhenoscapeOwlTools/phenoscape-owl-tools/pipeline/phenoscape-kb.sh
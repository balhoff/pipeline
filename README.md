# Overview
Build pipeline for the Phenoscape Knowledgebase


## Aims
Current version of the [pipeline](https://github.com/phenoscape/phenoscape-owl-tools/tree/master/pipeline) to be replaced with a newer version built in accordance with the following aims:

* Modularize the pipeline
* Institute quality control measures
* Use generic (commoditized) tools ([robot](http://robot.obolibrary.org/), [dosdp](https://github.com/INCATools/dead_simple_owl_design_patterns), etal)

## Projects

### Pipeline Refactoring
1. Loading and reasoning core Phenoscape data
2. Auto-generating axioms
3. Importing Model Organism data
4. Semantic similarity

### Quality Control Automation
* Create automated test suite for all the parts of the pipeline
* Formal and machine-testable definitions of OWL/RDF model expectations
    * ShEx
    * SHACL
    * SPARQL Queries
    
    
***

## Deployment

Docker image `phenoscape/pipeline-tools` packages the software tools required to run the KB build pipeline.

`run.sh` pulls the image and launches the container with the specified command to build the pipeline.

To build the entire pipeline:
```
./run.sh make all
```
To build a specific component of pipeline, like for instance `semantic similarity scores`:
```
./run.sh make ss-scores-gen
```


# Documentation

The build workflow can be found [here](https://github.com/phenoscape/pipeline/blob/master/docs/kb-build-flow.pdf).

The build process involves 

1. Importing/mirroring ontologies given in [ontologies.ofn](https://github.com/phenoscape/pipeline/blob/master/ontologies.ofn)
2. Downloading [data] (https://github.com/phenoscape/phenoscape-data) annotated by curators using [Phenex] (https://github.com/phenoscape/Phenex) (NeXML files)
3. Downloading ontologies developed by the [MONARCH Initiative](https://monarchinitiative.org/) - MGI, ZFIN, HPOA

All these ontologies are merged into a single ontology, reasoned over to generate tbox and abox axioms, and finally combined together to form the Phenoscape-KB.

`ontology-versions.ttl` contains metadata about the ontologies used in a particular kb build.

config: "Config.yaml"


rule create_artifact:
    input:
        config["samples"]

    output:
        "resuts/Qiime_objects/sequences.qzv"    

    shell:
        
rule cutadapt:
    input:
        "resuts/Qiime_objects/sequences.qza"

    output:
        'results/Qiime_objects/trimmed_sequences.qza

    threads:
        config["threads"]

    params:
        r1 = config["read1_adapter"] 
        r2 = config["read2_adapter"]
        len = config["cutadapt_min_len"]   

    shell:
        """
        qiime cutadapt trim-paired -i {input} \
        --p-cores {threads} --p-adapter-f {params.r1} \
        --p-adapter-r {params.r2} \
        --p-minimum-length {params.len} \
        --o-trimmed-sequences {output}
        """"  

rule vsearch:
    input:
         "resuts/Qiime_objects/trimmed_sequences.qza"

    output:
         "resuts/Qiime_objects/joined.qza"

   shell:
   """"    
    qiime vsearch join-pairs \
  --i-demultiplexed-seqs {input} \
  --o-joined-sequences {output}
    """"

rule summarize:
    input:
         "resuts/Qiime_objects/joined.qza"

    output:
        "results/Qiime_objects/joined.qzv"

    shell: """"    
    qiime demux summarize \
    --i-data {input} \
    --o-visualization {output} \
    """"

rule quality_filter:
    input:
        "results/Qiime_objects/joined.qza"

    output:
         qza = "results/Qiime_objects/joined_filtered.qza",
         stats = "results/Qiime_objects/joined_filtered_stats.qza"

    shell: """"
    qiime quality-filter q-score-joined \
    --i-demux {input} \
    --o-filtered-sequences {output.qza} \
    --o-filter-stats {output.stats}
    """"

rule deblur:
    input:
        qza = "results/Qiime_objects/joined_filtered.qza"

    output:    
      rep_seqs = "results/Qiime_obects/rep-seqs_deblur.qza",
      table = "results/Qiime_objects/table.qza",
      stats = "results/Qiime_obects/deblur_stats.qza"

    shell:""""
    qiime deblur denoise-16S \
    --i-demultiplexed-seqs {input} \
    --p-sample-stats \
    --o-representative-sequences {output.rep_seqs} \
    --p-trunc-len 0 \
    --o-table {output.table} \
    --o-stats {output.stats}
    """"

rule classification:
    input:
        "results/Qiime_obects/rep-seqs_deblur.qza"

    output:
        "results/Qiime_obects/rep_taxonomy.gza"    

    params:
        reads = config["reference"]
        tax = config["taxonomy"]

    shell: """
        qiime feature-classifier classify-consensus-blast \
            --i-reference-reads {params.reads} \
            --i-reference-taxonomy {params.tax} \
            --i-query {input} \
            --p-strand both \
            --o-classification {output}  
        """"      

rule taxa_collapse: 
    input:
        table = "results/Qiime_objects/table.qza",
        tax = "results/Qiime_objects/rep_taxonomy.qza"

    output:
        sp = "results/Qiime_objects/collapsed.qza"

    shell:
    """"
        qiime taxa collapse \
             --i-table {input.table} \
             --i-taxonomy {input.tax} \
             --o-collapsed-table {output} \
             --p-level 6
   """"

rule tax_barplot:
    input:
        table = "results/Qiime_objects/table.qza",
        tax = "results/Qiime_objects/rep_taxonomy.qza" 
        sample = config["samples"]

    output:
        "results/Visualizations/tax_barplot"          

    shell:
    """
    qiime taxa barplot \
             --i-table {input.table} \
             --i-taxonomy {input.tax} \
             --o-visualization {output} \
             --m-metadata-file {input.sample}
    """"             

rule export:
    input:
        "results/Qiime_objects/collapsed.qza"

    output:
        'results/Export/ASV'    

    shell:
    """
    qiime tools export \
             --input-path {input} \
             --output-path {output}

    "''
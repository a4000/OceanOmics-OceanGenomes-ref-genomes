process GFASTATS2 {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gfastats:1.3.6--hdcf5f25_3':
        'biocontainers/gfastats:1.3.6--hdcf5f25_3' }"

    input:
    tuple val(meta), path(assembly), path(stats)   // input.[fasta|fastq|gfa][.gz]
    val out_fmt                       // output format (fasta/fastq/gfa)
    val target                        // target specific sequence by header, optionally with coordinates (optional).
    val haplotype
    val asmversion                     // tells you what stage the assembly is in
    path agpfile                      // -a --agp-to-path <file> converts input agp to path and replaces existing paths.
    path include_bed                  // -i --include-bed <file> generates output on a subset list of headers or coordinates in 0-based bed format.
    path exclude_bed                  // -e --exclude-bed <file> opposite of --include-bed. They can be combined (no coordinates).
    path instructions                 // -k --swiss-army-knife <file> set of instructions provided as an ordered list.


    output:
    tuple val(meta), path("*.assembly_summary.txt"), emit: assembly_summary
    path "versions.yml"                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def agp  = agpfile ? "--agp-to-path $agp" : ""
    def ibed = include_bed ? "--include-bed $include_bed" : ""
    def ebed = exclude_bed ? "--exclude-bed $exclude_bed" : ""
    def sak  = instructions ? "--swiss-army-knife $instructions" : ""
    """
    # Get genomesize from $stats file
    genome_size=\$(cat $stats | grep 'Genome Unique Length' | grep -o 'bp.*' | sed 's/bp//g' | sed 's/ //g' | sed 's/,//g')

    gfastats \\
        $args \\
        --threads $task.cpus \\
        $agp \\
        $ibed \\
        $ebed \\
        $sak \\
        --out-format ${prefix}.${asmversion}.${haplotype}.${out_fmt} \\
        $assembly \\
        \$genome_size \\
        $target \\
        > ${prefix}.${asmversion}.${haplotype}.assembly_summary.txt

    touch "${prefix}.${asmversion}.${haplotype}.${out_fmt}"


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gfastats: \$( gfastats -v | sed '1!d;s/.*v//' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.${asmversion}.${haplotype}.${out_fmt}
    touch ${prefix}.${asmversion}.${haplotype}.assembly_summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gfastats: \$( gfastats -v | sed '1!d;s/.*v//' )
    END_VERSIONS
    """
}

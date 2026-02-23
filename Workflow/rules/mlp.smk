## Microbial Load Predictor

rule install_mlp_package:
    output:
        installed = mlp_dir + "/.mlp_package_installed"
    conda:
        workflow.basedir + "/Workflow/envs/mlp.yaml"
    log:
        log_dir + "/mlp/install_package.log"
    shell:
        """
        Rscript -e "
        # Install MLP from GitHub
        if (!require('MLP', quietly = TRUE)) {{
            cat('Installing MLP package from GitHub...\\n')
            remotes::install_github('grp-bork/microbial_load_predictor', upgrade = 'never', force = TRUE)
        }}
        
        # Verify installation
        library(MLP)
        cat('MLP package version:', as.character(packageVersion('MLP')), '\\n')
        
        # Check for model files
        pkg_extdata <- system.file('extdata', package = 'MLP')
        cat('MLP extdata location:', pkg_extdata, '\\n')
        
        if (pkg_extdata == '') {{
            stop('MLP package installed but extdata not found!')
        }}
        
        # List model files
        model_files <- list.files(file.path(pkg_extdata, 'galaxy'), pattern = '.rds$', full.names = TRUE)
        cat('Found', length(model_files), 'model files\\n')
        
        if (length(model_files) == 0) {{
            stop('MLP installed but model files are missing!')
        }}
        " 2> {log}
        
        touch {output.installed}
        """

rule mlp:
    input:
        profile = metaphlan_dir + "/table/abundance_species.txt"
    output:
        load = mlp_dir + "/load.tsv",
        qmp  = mlp_dir + "/qmp.tsv"
    conda:
        workflow.basedir + "/Workflow/envs/mlp.yaml"
    log:
        log_dir + "/mlp/mlp.log"
    resources:
        mem_mb = 8000,
        runtime = 60
    threads: 1
    script:
        workflow.basedir + "/Workflow/scripts/mlp.R"
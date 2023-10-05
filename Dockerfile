FROM davidemms/orthofinder:2.5.5.1

Label maintainer="rdemko2332@gmail.com"

RUN apt-get update && apt-get install -y default-jre samtools seqtk procps mafft bioperl && apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /usr/bin/

RUN mkdir -p ~/miniconda3
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
RUN bash ~/miniconda3/miniconda.sh -b -u -p /usr/bin/miniconda3
RUN rm -rf ~/miniconda3/miniconda.sh
RUN /usr/bin/miniconda3/bin/conda init bash
RUN /usr/bin/miniconda3/bin/conda init zsh
RUN /usr/bin/miniconda3/bin/conda install -c bioconda bmge
RUN /usr/bin/miniconda3/bin/conda install -c bioconda fastme
RUN /usr/bin/miniconda3/bin/conda install -c bioconda fasttree
RUN mv /usr/bin/miniconda3/bin/fasttree /usr/bin/fasttree
RUN mv /usr/bin/miniconda3/bin/bmge /usr/bin/bmge
RUN mv /usr/bin/miniconda3/bin/fastme /usr/bin/fastme

ADD /bin/*.pl /usr/bin/

# Making all tools executable
RUN chmod +x *

ADD /bin/orthologues.py /opt/OrthoFinder_source/scripts_of/orthologues.py
ADD /bin/__main__.py /opt/OrthoFinder_source/scripts_of/__main__.py
ADD /bin/parallel_task_manager.py /opt/OrthoFinder_source/scripts_of/parallel_task_manager.py

WORKDIR /work
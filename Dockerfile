FROM davidemms/orthofinder:2.5.5.1

Label maintainer="rdemko2332@gmail.com"

RUN apt-get update && apt-get install -y bioperl samtools seqtk procps && apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /usr/bin/

ADD /bin/**/*.pl /usr/bin/

# Making all tools executable
RUN chmod +x *

ADD /bin/orthologues.py /opt/OrthoFinder_source/scripts_of/orthologues.py
ADD /bin/__main__.py /opt/OrthoFinder_source/scripts_of/__main__.py
ADD /bin/parallel_task_manager.py /opt/OrthoFinder_source/scripts_of/parallel_task_manager.py

WORKDIR /work

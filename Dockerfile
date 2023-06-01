FROM davidemms/orthofinder:2.5.5.1

Label maintainer="rdemko2332@gmail.com"

ADD /bin/orthologues.py /opt/OrthoFinder_source/scripts_of/orthologues.py

WORKDIR /work
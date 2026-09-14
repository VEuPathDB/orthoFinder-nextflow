FROM davidemms/orthofinder:2.5.5.2

Label maintainer="rdemko2332@gmail.com"

# deb.debian.org has pruned the bullseye/bullseye-security point-release packages this
# image pins (build started failing with plain 404s on unrelated packages -- gnupg2,
# libfcgi, glib2.0-data, perl-doc -- all at once, the signature of a whole suite being
# removed from the live mirror, not a single missing file). Pin to the snapshot.debian.org
# date this base image's own (commented-out) sources.list already names for reproducibility;
# Check-Valid-Until=false is required since a frozen snapshot's Release file has long since
# "expired". Retries/Timeout guard against snapshot.debian.org's own occasional slowness
# under load (confirmed via a live rebuild: without them a handful of packages 504'd; with
# them the same install completes cleanly).
RUN sed -i \
      -e "s|deb http://deb.debian.org/debian-security bullseye-security main|deb http://snapshot.debian.org/archive/debian-security/20230502T000000Z bullseye-security main|" \
      -e "s|deb http://deb.debian.org/debian bullseye main|deb http://snapshot.debian.org/archive/debian/20230502T000000Z bullseye main|" \
      -e "s|deb http://deb.debian.org/debian bullseye-updates main|deb http://snapshot.debian.org/archive/debian/20230502T000000Z bullseye-updates main|" \
      /etc/apt/sources.list \
 && apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Retries=5 -o Acquire::http::Timeout=90 update \
 && apt-get -o Acquire::Retries=5 -o Acquire::http::Timeout=90 install -y default-jre samtools seqtk procps mafft bioperl cpanminus \
 && apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/*

WORKDIR /usr/bin/

RUN mkdir -p ~/miniconda3
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
RUN bash ~/miniconda3/miniconda.sh -b -u -p /usr/bin/miniconda3
RUN rm -rf ~/miniconda3/miniconda.sh
RUN miniconda3/bin/conda init bash
RUN miniconda3/bin/conda init zsh
RUN miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
RUN miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
RUN miniconda3/bin/conda install -c bioconda fasttree
RUN mv miniconda3/bin/fasttree fasttree

RUN cpanm Statistics::Basic Statistics::Descriptive::Weighted

RUN wget http://github.com/bbuchfink/diamond/releases/download/v2.0.15/diamond-linux64.tar.gz
RUN tar xzf diamond-linux64.tar.gz

RUN wget https://github.com/marbl/Mash/releases/download/v2.3/mash-Linux64-v2.3.tar
RUN tar -xf mash-Linux64-v2.3.tar --no-same-owner
RUN mv mash-Linux64-v2.3/mash /usr/bin

# Making all tools executable
RUN chmod +x *

ADD /bin/orthologues.py /opt/OrthoFinder_source/scripts_of/orthologues.py
ADD /bin/__main__.py /opt/OrthoFinder_source/scripts_of/__main__.py
ADD /bin/parallel_task_manager.py /opt/OrthoFinder_source/scripts_of/parallel_task_manager.py

ADD /bin/* /usr/bin/

WORKDIR /work

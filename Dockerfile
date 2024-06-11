FROM mambaorg/micromamba:1.5.8


ARG MAMBA_DOCKERFILE_ACTIVATE=1

COPY --chown=$MAMBA_USER:$MAMBA_USER env.yml /tmp/
RUN micromamba install -q --name base --yes --file /tmp/env.yml \
    && rm /tmp/env.yml \
    && micromamba clean --yes --all

ENV MATLAB_VERSION=R2017b
ENV MCR_VERSION=v93
USER root
ADD --chown=$MAMBA_USER:$MAMBA_USER https://ssd.mathworks.com/supportfiles/downloads/${MATLAB_VERSION}/deployment_files/${MATLAB_VERSION}/installers/glnxa64/MCR_${MATLAB_VERSION}_glnxa64_installer.zip /tmp/
RUN unzip -q /tmp/MCR_${MATLAB_VERSION}_glnxa64_installer.zip -d /tmp/mcr_install \
    && /tmp/mcr_install/install -destinationFolder /opt/mcr -agreeToLicense yes -mode silent \
    && rm -rf /tmp/mcr_install /tmp/*

# Install SPM Standalone in /opt/spm12/
ENV SPM_VERSION=12
ENV SPM_REVISION=r7219
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/mcr/${MCR_VERSION}/runtime/glnxa64:/opt/mcr/${MCR_VERSION}/bin/glnxa64:/opt/mcr/${MCR_VERSION}/sys/os/glnxa64:/opt/mcr/${MCR_VERSION}/sys/opengl/lib/glnxa64:/opt/conda/lib
ENV MCR_INHIBIT_CTF_LOCK=1
ADD --chown=$MAMBA_USER:$MAMBA_USER https://www.fil.ion.ucl.ac.uk/spm/download/restricted/bids/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip /tmp/
RUN unzip -q /tmp/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip -d /opt \
    && rm -f /opt/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip \
    && /opt/spm${SPM_VERSION}/spm${SPM_VERSION} function exit \
    && rm /tmp/spm${SPM_VERSION}_${SPM_REVISION}_Linux_${MATLAB_VERSION}.zip

# Unzip 2.1 in brainageR directory
ENV BRAINAGER_VERSION=2.1
ENV BRAINAGER_DIR=/opt/brainageR
ENV BRAINAGER_SOFTWARE_DIR=${BRAINAGER_DIR}/software
ADD --chown=$MAMBA_USER:$MAMBA_USER https://github.com/james-cole/brainageR/archive/refs/tags/${BRAINAGER_VERSION}.zip /tmp/
RUN mkdir -p ${BRAINAGER_SOFTWARE_DIR} \
    && unzip /tmp/${BRAINAGER_VERSION}.zip -d /tmp \
    && mv /tmp/brainageR-${BRAINAGER_VERSION}/* ${BRAINAGER_SOFTWARE_DIR} \
    && rm /tmp/${BRAINAGER_VERSION}.zip

# update ownership so that people don't need to be root
# inside the container
RUN chown -R $MAMBA_USER:$MAMBA_USER /opt/spm${SPM_VERSION} \
    && chown -R $MAMBA_USER:$MAMBA_USER /opt/mcr \
    && chown -R $MAMBA_USER:$MAMBA_USER ${BRAINAGER_DIR}

USER $MAMBA_USER
# Download PCs
ADD --chown=$MAMBA_USER:$MAMBA_USER https://github.com/james-cole/brainageR/releases/download/${BRAINAGER_VERSION}/pca_center.rds ${BRAINAGER_SOFTWARE_DIR}
ADD --chown=$MAMBA_USER:$MAMBA_USER https://github.com/james-cole/brainageR/releases/download/${BRAINAGER_VERSION}/pca_rotation.rds ${BRAINAGER_SOFTWARE_DIR}
ADD --chown=$MAMBA_USER:$MAMBA_USER https://github.com/james-cole/brainageR/releases/download/${BRAINAGER_VERSION}/pca_scale.rds ${BRAINAGER_SOFTWARE_DIR}

ENV SPM_BIN=/opt/spm${SPM_VERSION}/spm${SPM_VERSION}
# # Configure entry point
ENV FSLDIR=/opt/conda
ENV FSLOUTPUTTYPE=NIFTI_GZ
COPY --chown=$MAMBA_USER:$MAMBA_USER spm_preprocess_brainageR.m ${BRAINAGER_SOFTWARE_DIR}
COPY --chmod=0775 --chown=$MAMBA_USER:$MAMBA_USER brainageR /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/_entrypoint.sh", "/usr/local/bin/brainageR"]
CMD ["-h"]

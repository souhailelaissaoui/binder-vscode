FROM jupyter/datascience-notebook:lab-2.2.9
ENV HTTPS_PROXY="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV HTTP_PROXY="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV http_proxy="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV https_proxy="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"

RUN	rm -rf /home/jovyan  && \
	mkdir /home/jovyan && \
	chown $NB_UID:$NB_GID /home/jovyan

USER	$NB_UID

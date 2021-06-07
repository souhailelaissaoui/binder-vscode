FROM jupyter/datascience-notebook:lab-2.2.9
ENV HTTPS_PROXY="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV HTTP_PROXY="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV http_proxy="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
ENV https_proxy="http://proxy-gdpshs-p.we1.azure.aztec.cloud.allianz:80"
WORKDIR /app
COPY . .
RUN yarn install --production
CMD ["node", "src/index.js"]

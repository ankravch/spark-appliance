FROM registry.opensource.zalan.do/stups/python:3.5.2-38
MAINTAINER Team Lago <team-lago@zalando.de>

ENV SPARK_VERSION="2.0.1-SNAPSHOT" HADOOP_VERSION="2.7.2"
ENV SPARK_PACKAGE="spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}"
ENV SPARK_DIR="/opt/${SPARK_PACKAGE}"

RUN apt-get update && apt-get install wget openjdk-8-jdk -y --force-yes
RUN pip3 install --upgrade kazoo boto3 connexion gevent uwsgi

### installing Jupyter notebook, remove this RUN if you do not need those features.
RUN apt-get install -yq --force-yes --no-install-recommends build-essential python3-dev \
 && pip3 install --upgrade py4j jupyter

### installing spark kernel for Jupyter notebook, remove this RUN if you do not need this feature.
RUN wget https://s3.eu-central-1.amazonaws.com/saiki-spark/toree-0.2.0.dev1-incubating-binary-release.tar.gz -O /tmp/toree-0.2.0.dev1-incubating-binary-release.tar.gz \
 && tar zxf /tmp/toree-0.2.0.dev1-incubating-binary-release.tar.gz -C /opt \
 && rm  -rf /tmp/toree-0.2.0.dev1-incubating-binary-release.tar.gz


### installing python libraries for data analyzing, remove this RUN if you do not need this feature.
RUN pip3 install --upgrade numpy \
 && apt-get install -y --force-yes python3-scipy python3-matplotlib

### DOWNLOADING spark package, ALWAYS NEEDED
RUN wget  https://s3-eu-west-1.amazonaws.com/zalando-spark/${SPARK_PACKAGE}.tgz -O /tmp/${SPARK_PACKAGE}.tgz \
 && tar zxf /tmp/${SPARK_PACKAGE}.tgz -C /opt \
 && rm -rf /tmp/${SPARK_PACKAGE}.tgz \
 && chmod -R 777 $SPARK_DIR

### CONFIGURING spark and hadoop, ALWAYS NEEDED - this core-site allows filesystem based credentials as well as EC2 env
ADD core-site.xml $SPARK_DIR/conf/
RUN mv $SPARK_DIR/conf/emrfs-default.xml.zalando $SPARK_DIR/conf/emrfs-default.xml \
 && mv $SPARK_DIR/conf/spark-defaults.conf.zalando $SPARK_DIR/conf/spark-defaults.conf \
 && mv $SPARK_DIR/conf/spark-env.sh.zalando $SPARK_DIR/conf/spark-env.sh \
 && mkdir /tmp/s3 && mkdir /tmp/spark-events && chmod -R 777 /tmp

COPY beeline.tar.gz /tmp/
RUN tar zxf /tmp/beeline.tar.gz -C /opt

### UPLOADING files for webapp, optional
COPY swagger.yaml /opt/
COPY webapp.py /opt/

### UPLOADING entry point of docker, ALWAYS NEEDED
COPY utils.py /opt/
COPY start_all.py /opt/
RUN chmod 777 /opt/start_all.py

### UPLOADING files for Jupyter notebook, optional
COPY kernel.json /tmp/
COPY start_notebook.sh /opt/
RUN chmod 777 /opt/start_notebook.sh

### scm-source file for STUPS policy compliant, use build-scm-source.sh to build it
COPY scm-source.json /

WORKDIR /opt

CMD /opt/start_all.py

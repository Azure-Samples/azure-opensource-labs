FROM alpine:latest
RUN wget https://github.com/jozu-ai/kitops/releases/latest/download/kitops-linux-x86_64.tar.gz && \
  tar -xzvf kitops-linux-x86_64.tar.gz && \
  mv kit /usr/local/bin/

# Set default values for environment variables
ENV UNPACK_PATH=/home/user/modelkit/
ENV UNPACK_FILTER=model

CMD echo $PASSWORD | kit login $REGISTRY_URL -u $USERNAME --password-stdin && \
  kit unpack "$MODELKIT_REF" --dir "$UNPACK_PATH" --filter="$UNPACK_FILTER"
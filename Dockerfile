FROM --platform=linux/amd64 python:3.11-slim AS builder
LABEL source_repository="https://github.com/sapcc/curator-opensearch"

# Add the community repo for access to patchelf binary package
RUN apt-get update && apt-get install -y build-essential
# patchelf-wrapper is necessary now for cx_Freeze, but not for Curator itself.
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
RUN pip3 install cx_Freeze patchelf-wrapper

COPY . .
RUN ln -s /lib/libc.musl-x86_64.so.1 ldd
RUN ln -s /lib /lib64
RUN python3 setup.py build_exe

FROM --platform=linux/amd64 alpine:3.21
LABEL source_repository="https://github.com/sapcc/curator-opensearch"
RUN apk --no-cache upgrade && apk --no-cache add openssl-dev expat bash vim
COPY --from=builder build/exe.linux-x86_64-3.11 /curator/
RUN mkdir /.curator

#USER nobody:nobody
ENV LD_LIBRARY_PATH /curator/lib:$LD_LIBRARY_PATH
ENTRYPOINT ["/curator/curator"]


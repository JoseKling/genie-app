FROM julia:1.11
RUN apt-get update && apt-get install -y vim
RUN useradd --create-home --shell /bin/bash genie
RUN mkdir /home/genie/app
COPY . /home/genie/app
WORKDIR /home/genie/app
RUN chown -R genie:genie /home/
USER genie
ENV JULIA_DEPOT_PATH "/home/genie/.julia"
ENV JULIA_REVISE = "off"
ENV GENIE_ENV "prod"
ENV GENIE_HOST "0.0.0.0"
ENV WSPORT $PORT
ENV EARLYBIND "true"
ENV JULIA_CPU_TARGET="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)"
RUN julia -e "using Pkg; Pkg.activate(\".\"); Pkg.instantiate(); Pkg.precompile(); "
ENTRYPOINT ["julia", "--project", "-e", "using GenieFramework; Genie.loadapp(); up(async=false);"]

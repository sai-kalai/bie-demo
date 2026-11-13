FROM julia:1.12

ENV JULIA_CPU_THREADS=4

WORKDIR /app

COPY Project.toml ./

RUN apt-get update && apt-get install -y time

RUN /usr/bin/time -v julia --project=. -e 'using Pkg; Pkg.instantiate(; verbose=true)'

COPY . .

RUN /usr/bin/time -v julia --project=. -e 'using Pkg; Pkg.precompile()'

EXPOSE 8080

CMD ["julia", "--project=.", "-e", "using DemoWebsite; DemoWebsite.main()"]

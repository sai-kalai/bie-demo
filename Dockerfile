FROM julia:1.12

ENV JULIA_NUM_THREADS=auto

WORKDIR /app

COPY Project.toml ./

RUN julia --project=. -e 'using Pkg; Pkg.instantiate(; verbose=true)'

COPY . .

RUN julia --project=. -e 'using Pkg; Pkg.precompile()'

EXPOSE 8080

CMD ["julia", "--project=.", "-e", "using DemoWebsite; DemoWebsite.main()"]

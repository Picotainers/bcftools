# bcftools
Source-built `bcftools` container.

## how to use
```bash
docker run --rm -v "$(pwd):/data" picotainers/bcftools:latest --help
```

## example
```bash
docker run --rm -v "$(pwd):/data" picotainers/bcftools:latest view -H /data/input.vcf
```

# ssddata 2.0.0

This is a major update to a package already on CRAN (1.0.0, 2021-09-13). It adds
39 new benchmark data sets (ANZG guideline data sets, `anztox_data`,
`wqbench_data` and the EnviroTox data sets) and corrects several errors in the
existing ones, including concentration units that were stored on the wrong scale.

## Test environments

* local: Debian (WSL2), R 4.6.1 -- `R CMD check --as-cran`
* win-builder: R-devel, R-release
* macbuilder: R-release

## R CMD check results

0 errors | 0 warnings | 0 notes

The only note seen locally is environmental and not a property of the package:

```
* checking HTML version of manual ... NOTE
Skipping checking HTML validation: no command 'tidy' found.
```

## Reverse dependencies

`ssdtools` (2.6.0) is the only reverse dependency; it imports `ssddata`.

`R CMD check` on `ssdtools` 2.6.0 against `ssddata` 2.0.0 gives **Status: OK**.

Checked additionally with `NOT_CRAN=true`, which enables `ssdtools`' snapshot
tests (1275 pass, 38 skip, 4 fail):

* Three snapshot failures in `test-censor.R` are caused by this release:
  `ccme_boron` gains a `Medium` column, so the snapshot's column set differs.
  The concentration values are unchanged.
* One failure (`test-hc.R:853`, `ssd_hc fitdists arithmetic_samples ci`) is
  **not** caused by this release -- it reproduces identically with `ssddata`
  1.0.0 installed. It is a bootstrap confidence-interval snapshot.

Both are `testthat` file snapshots, which skip on CRAN; hence the OK status
above. The `ssdtools` maintainer has been notified so the three affected
snapshots can be regenerated.

## Notes for the reviewer

* `https://commonchemistry.cas.org`, linked from the `ANZTOX data processing`
  vignette, returns HTTP 403 to automated requests (including with a browser
  user-agent). The URL is valid and resolves normally in a browser.
* The package uses quarto vignettes (`VignetteBuilder: quarto`); `quarto` is
  listed in `Suggests`.

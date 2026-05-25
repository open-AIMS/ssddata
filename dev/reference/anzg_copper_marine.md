# Species Sensitivity Data for copper_marine

Species Sensitivity Data provided by the Department of Agriculture Water
and the Environment, Australia. This data underpins the ANZG default
guideline for ***copper*** in marine water.

## Format

An object of class `tbl_df` (inherits from `tbl`, `data.frame`) with 45
rows and 9 columns.

## Details

These data are licensed under CC BY 4.0 (summary of terms provided here:
<https://creativecommons.org/licenses/by/4.0/>) Additional information
is available from the Water Quality website at
<https://www.waterquality.gov.au/>

Please cite these data as: ANZG (2025). “Toxicant default guideline
values for aquatic ecosystem protection: Copper in marine water.”
Australian and New Zealand Governments and Australian State and
Territory Governments, Canberra, Australia.
<https://www.waterquality.gov.au/anz-guidelines/guideline-values/default/water-quality-toxicants/toxicants/copper-marine-2025>.

The columns are as follows:

- Conc:

  The chemical concentration in micrograms per Litre (dbl).

- Duration:

  The duration of the test in days (chr).

- Genus:

  The Genus name (chr).

- Group:

  The taxonomic group (chr).

- Life_stage:

  Life stage of the test organism (chr).

- Phylum:

  The Phylum name (chr).

- Species:

  The species binomial name (chr).

- Test_endpoint:

  The test endpoint measure (chr).

- Toxicity_measure:

  The toxicity measure used (chr).

## Examples

``` r

print(anzg_copper_marine, n=Inf)
#> # A tibble: 45 × 9
#>      Conc Duration Genus         Group   Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>         <chr>   <chr>      <chr>  <chr>   <chr>        
#>  1   1.4  3        Entomoneis    Diatom  Exponenti… Bacil… punctu… Population g…
#>  2   0.2  3        Minutocellus  Diatom  Exponenti… Bacil… polymo… Population g…
#>  3   3.3  3        Ceratoneis    Diatom  Exponenti… Bacil… closte… Population g…
#>  4   1    3        Phaeodactylum Diatom  Exponenti… Bacil… tricor… Population b…
#>  5   8.5  3        Coccolithus   Golden… Exponenti… Hapto… huxleyi Population g…
#>  6   1.3  3        Gephyrocapsa  Golden… Exponenti… Hapto… oceani… Population g…
#>  7   0.84 3        Proteomonas   Golden… Exponenti… Hapto… sulcata Population g…
#>  8   2.7  3        Tisochrysis   Golden… Exponenti… Hapto… lutea   Population g…
#>  9 300    3        Cyanobium     Cyanob… Exponenti… Cyano… sp.     Population a…
#> 10   8    3        Dunaliella    Green … Exponenti… Chlor… tertio… Population g…
#> 11   0.3  3        Micromonas    Green … Exponenti… Chlor… pusilla Population g…
#> 12   7    3        Tetraselmis   Green … Exponenti… Chlor… sp.     Population g…
#> 13  27    4        Ulva          Green … Zoospore   Chlor… fascia… Reproduction 
#> 14  56    3        Ulva          Green … Zoospore   Chlor… lactuca Settlement a…
#> 15   4.1  20       Macrocystis   Brown … Zoospore   Ochro… pyrife… Sporophyte p…
#> 16  17    14       Fucus         Brown … Germling   Ochro… vesicu… Growth       
#> 17   5.8  0.2      Acropora      Cnidar… Gamete     Cnida… aspera  Fertilisation
#> 18  15.3  0.2      Acropora      Cnidar… Gamete     Cnida… longic… Fertilisation
#> 19  34    0.2      Acropora      Cnidar… Gamete     Cnida… tenuis  Fertilisation
#> 20  13    0.2      Coelastrea    Cnidar… Gamete     Cnida… aspera  Fertilisation
#> 21  16    0.2      Platygyra     Cnidar… Gamete     Cnida… daedal… Fertilisation
#> 22   9.8  28       Exaiptasia    Cnidar… Adult      Cnida… diapha… Reproduction 
#> 23   9.6  2        Diadema       Echino… Embryo     Echin… savign… Development  
#> 24   2.1  3        Evechinus     Echino… Larva      Echin… chloro… Development  
#> 25   6.2  8        Hydroides     Annelid Gamete     Annel… elegans Metamorphosis
#> 26   2.5  2        Anadara       Mollusc Embryo     Mollu… trapez… Development  
#> 27   4.5  2        Barnea        Mollusc Embryo     Mollu… austra… Development  
#> 28   3.6  2        Fulvia        Mollusc Embryo     Mollu… tenuic… Development  
#> 29   3.8  2        Hiatula       Mollusc Embryo     Mollu… alba    Development  
#> 30   6    2        Irus          Mollusc Embryo     Mollu… crenat… Development  
#> 31   1.4  2        Magallana     Mollusc Embryo     Mollu… gigas   Development  
#> 32   2    2        Mimachlamys   Mollusc Larva      Mollu… asperr… Development  
#> 33   4.8  2        Mytilus       Mollusc Embryo     Mollu… gallop… Development  
#> 34   4.2  2        Mytilus       Mollusc Embryo     Mollu… trosso… Development  
#> 35   1.5  14       Saccostrea    Mollusc Larva      Mollu… glomer… Mortality    
#> 36   2.2  2        Scaeochlamys  Mollusc Embryo     Mollu… livida  Development  
#> 37   5    2        Spisula       Mollusc Embryo     Mollu… trigon… Development  
#> 38   1.9  2        Xenostrobus   Mollusc Embryo     Mollu… securis Development  
#> 39   0.7  3        Haliotis      Gastro… Larva      Mollu… iris    Development  
#> 40   3.7  4        Nassarius     Gastro… Larvae     Mollu… dorsat… Larval growth
#> 41   1    3.3      Acartia       Crusta… Eggs       Arthr… sinjie… Larval devel…
#> 42  10    4        Amphibalanus  Crusta… Larva      Arthr… amphit… Metamorphosis
#> 43  19    100      Tisbe         Crusta… Life cycle Arthr… furcata Survival and…
#> 44  62    12       Atherinops    Fish    Larva      Chord… affinis Development  
#> 45  21    25       Epinephelus   Fish    Juvenile   Chord… coioid… Growth       
#> # ℹ 1 more variable: Toxicity_measure <chr>
```

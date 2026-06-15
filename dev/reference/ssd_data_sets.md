# List SSD Datasets

Returns a named list of SSD datasets from ssddata.

## Usage

``` r
ssd_data_sets(
  set = "v2",
  split = NULL,
  summarize = "geomean",
  cas_lookup = TRUE
)
```

## Arguments

- set:

  A string or character vector controlling which datasets are returned.
  Options:

  - `"v2"` (default): all current individual non-aggregate datasets

  - `"v1"`: fixed set of 20 datasets from ssddata v1

  - one or more prefix strings e.g. `c("ccme", "anzg")`: filters v2 by
    prefix

  - `"wqbench"`: splits `wqbench_data` by `Chemical`

  - `"envirotox_acute"`: splits `envirotox_acute` by `Chemical`

  - `"envirotox_chronic"`: splits `envirotox_chronic` by `Chemical`

  - `"anztox"`: splits `anztox_data` by `chemicalname_grouped` x
    `mediatype`

  - `"alldata"`: aggregates all `*_data` sources and splits by
    `Chemical`

  **Note:** aggregated values (`"wqbench"`, `"envirotox_acute"`,
  `"envirotox_chronic"`, `"anztox"`, `"alldata"`) must be passed alone —
  they cannot be combined with each other or with prefix strings (e.g.
  `c("wqbench", "ccme")` is not supported and will error).

- split:

  A character vector of column names to further split datasets by before
  returning. Columns absent from a dataset are silently skipped. Column
  values are appended to dataset names when the column is present.
  Default `NULL` applies no additional splitting.

- summarize:

  A string controlling how duplicate Species rows within a chemical are
  handled. `"geomean"` (default) applies a geometric mean and emits a
  message; `"none"` returns data as-is and emits a message listing
  duplicates.

- cas_lookup:

  A flag. When `TRUE` (default) and `set = "alldata"`, uses
  `data-raw/anztox/cas_parent_lookup.csv` to align chemical names/CAS
  numbers across datasets before splitting (currently a no-op hook).

## Value

A named list of tibbles. Every tibble is guaranteed to have `Species` as
the first column and `Conc` as the second column. Datasets with no
species information (`anon_*`) receive sequential species labels
(`"sp. A"`, `"sp. B"`, ...). Additional columns follow in their original
order.

## Examples

``` r
ssd_data_sets()
#> Geometric mean applied to duplicate species rows in: aims_aluminium_marine, anzg_boron_fresh.
#> $aims_aluminium_marine
#> # A tibble: 17 × 2
#>    Species                      Conc
#>    <chr>                       <dbl>
#>  1 Acropora tenuis            1300  
#>  2 Amphibalanus amphitrite     416  
#>  3 Ceratoneis closterium        27.2
#>  4 Coenobita variabilis        312  
#>  5 Dunaliella tertiolecta     1400  
#>  6 Ecklonia radiata           6800  
#>  7 Exaiptasia pallida          817  
#>  8 Heliocardis tuberculata   28000  
#>  9 Hormosira banksii          9800. 
#> 10 Minutocellus polymorphus    610  
#> 11 Mytilus edulis              250  
#> 12 Nassarius dorsatus          115  
#> 13 Phaeodactylum tricornutum  2100  
#> 14 Saccostrea glomerata        100  
#> 15 Saccrostrea echinata        410  
#> 16 Tetraselmis sp.            3200. 
#> 17 Tisochrysis lutea           640  
#> 
#> $aims_gallium_marine
#> # A tibble: 6 × 9
#>   Species              Conc Common Domain Life_stage Phylum Source Test_endpoint
#>   <chr>               <dbl> <chr>  <chr>  <chr>      <chr>  <chr>  <chr>        
#> 1 Ceratoneis closter…   860 Diatom Tropi… NA         Bacil… (Harf… EC10         
#> 2 Tisochrysis lutea …  6000 Golde… Tropi… NA         Hapto… (Tren… NOEC         
#> 3 Nassarius dorsatus   3800 Dog w… Tropi… Larva      Mollu… (Tren… EC10         
#> 4 Coenobita variabil…  6010 Austr… Tropi… Zoea       Crust… (van … EC10         
#> 5 Amphibalanus amphi…  5070 Strip… Tropi… Nauplius   Crust… (van … EC10         
#> 6 Acropora tenuis      1160 Branc… Tropi… Larva      Cnida… (Negr… EC10         
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $aims_molybdenum_marine
#> # A tibble: 14 × 9
#>    Species             Conc Common Domain Life_stage Phylum Source Test_endpoint
#>    <chr>              <dbl> <chr>  <chr>  <chr>      <chr>  <chr>  <chr>        
#>  1 Dunaliella terti… 8.81e5 Green… Tempe… NA         Chlor… (Heij… EC10         
#>  2 Phaeodactylum tr… 1.7 e5 Diatom Tempe… NA         Bacil… (Heij… EC10         
#>  3 Ceramium tenuico… 2.74e5 Red a… Tempe… Adult      Rhodo… (Heij… EC10         
#>  4 Crassostrea gigas 1.17e6 Pacif… Tempe… Embryo     Mollu… (Heij… EC10         
#>  5 Mytilus edulis    4.4 e3 Blue … Tempe… Embryo     Mollu… (Morg… EC10         
#>  6 Acartia tonsa     7.96e3 Copep… Tempe… Embryo     Crust… (Heij… EC10         
#>  7 Strongylocentrot… 3.26e5 Purpl… Tempe… Embryo     Echin… (Heij… EC10         
#>  8 Dendraster excen… 2.34e5 Pacif… Tempe… Embryo     Echin… (Heij… EC10         
#>  9 Tisochrysis lutea 9.5 e3 Golde… Tropi… NA         Hapto… (Tren… NOEC         
#> 10 Nassarius dorsat… 7   e3 Dog w… Tropi… Larva      Mollu… (Tren… NOEC         
#> 11 Coenobita variab… 1   e4 Austr… Tropi… Zoea       Crust… (van … NOEC         
#> 12 Amphibalanus amp… 9   e3 Strip… Tropi… Nauplius   Crust… (van … NOEC         
#> 13 Americamysis bah… 1.16e5 Mysid… Tropi… Larva      Crust… (Heij… NOEC         
#> 14 Cyprinodon varie… 8.41e4 Sheep… Tropi… Embryo     Chord… (Heij… EC10         
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anon_a
#> # A tibble: 18 × 4
#>    Species   Conc Chemical Medium 
#>    <chr>    <dbl> <chr>    <chr>  
#>  1 sp. A    500   a        Unknown
#>  2 sp. B   1800   a        Unknown
#>  3 sp. C    120   a        Unknown
#>  4 sp. D    490   a        Unknown
#>  5 sp. E      4   a        Unknown
#>  6 sp. F     16   a        Unknown
#>  7 sp. G   6250   a        Unknown
#>  8 sp. H    100   a        Unknown
#>  9 sp. I   7800   a        Unknown
#> 10 sp. J   7990   a        Unknown
#> 11 sp. K   1360   a        Unknown
#> 12 sp. L   4000   a        Unknown
#> 13 sp. M   1800   a        Unknown
#> 14 sp. N     36.4 a        Unknown
#> 15 sp. O    492   a        Unknown
#> 16 sp. P     50   a        Unknown
#> 17 sp. Q    200   a        Unknown
#> 18 sp. R   1600   a        Unknown
#> 
#> $anon_b
#> # A tibble: 10 × 4
#>    Species  Conc Chemical Medium 
#>    <chr>   <dbl> <chr>    <chr>  
#>  1 sp. A     1   b        Unknown
#>  2 sp. B     2.6 b        Unknown
#>  3 sp. C     5.1 b        Unknown
#>  4 sp. D     8.4 b        Unknown
#>  5 sp. E    13.8 b        Unknown
#>  6 sp. F    15.2 b        Unknown
#>  7 sp. G    20.7 b        Unknown
#>  8 sp. H    31.8 b        Unknown
#>  9 sp. I   114   b        Unknown
#> 10 sp. J   125   b        Unknown
#> 
#> $anon_c
#> # A tibble: 16 × 4
#>    Species     Conc Chemical Medium 
#>    <chr>      <dbl> <chr>    <chr>  
#>  1 sp. A       32   c        Unknown
#>  2 sp. B    17020   c        Unknown
#>  3 sp. C   143000   c        Unknown
#>  4 sp. D      470   c        Unknown
#>  5 sp. E       14   c        Unknown
#>  6 sp. F      248   c        Unknown
#>  7 sp. G        7.7 c        Unknown
#>  8 sp. H       20   c        Unknown
#>  9 sp. I       20   c        Unknown
#> 10 sp. J       20   c        Unknown
#> 11 sp. K      500   c        Unknown
#> 12 sp. L      500   c        Unknown
#> 13 sp. M      500   c        Unknown
#> 14 sp. N      500   c        Unknown
#> 15 sp. O      500   c        Unknown
#> 16 sp. P    13000   c        Unknown
#> 
#> $anon_d
#> # A tibble: 12 × 4
#>    Species  Conc Chemical Medium 
#>    <chr>   <dbl> <chr>    <chr>  
#>  1 sp. A    8944 d        Unknown
#>  2 sp. B   10000 d        Unknown
#>  3 sp. C    1650 d        Unknown
#>  4 sp. D    2700 d        Unknown
#>  5 sp. E   11800 d        Unknown
#>  6 sp. F    4800 d        Unknown
#>  7 sp. G     140 d        Unknown
#>  8 sp. H     229 d        Unknown
#>  9 sp. I     236 d        Unknown
#> 10 sp. J     550 d        Unknown
#> 11 sp. K    2226 d        Unknown
#> 12 sp. L    5530 d        Unknown
#> 
#> $anon_e
#> # A tibble: 17 × 4
#>    Species    Conc Chemical Medium 
#>    <chr>     <dbl> <chr>    <chr>  
#>  1 sp. A      11.2 e        Unknown
#>  2 sp. B      17   e        Unknown
#>  3 sp. C       3.4 e        Unknown
#>  4 sp. D       5.5 e        Unknown
#>  5 sp. E      20   e        Unknown
#>  6 sp. F    1376   e        Unknown
#>  7 sp. G       0.8 e        Unknown
#>  8 sp. H    8200   e        Unknown
#>  9 sp. I    3000   e        Unknown
#> 10 sp. J   29050   e        Unknown
#> 11 sp. K   11290   e        Unknown
#> 12 sp. L    7116   e        Unknown
#> 13 sp. M   13000   e        Unknown
#> 14 sp. N   16400   e        Unknown
#> 15 sp. O   16280   e        Unknown
#> 16 sp. P    7100   e        Unknown
#> 17 sp. Q     100   e        Unknown
#> 
#> $anzg_alpha_cypermethrin_fresh
#> # A tibble: 14 × 7
#>    Species             Conc Duration Genus     Group Life_stage Toxicity_measure
#>    <chr>              <dbl> <chr>    <chr>     <chr> <chr>      <chr>           
#>  1 flosaquae         27.2   96       Anabaena  Cyan… Not stated Chronic NOEC    
#>  2 pelliculosa       72     96       Navicula  Diat… Not stated Chronic NOEC    
#>  3 gibba              1.39  168      Lemna     Macr… Not stated Chronic NOEC    
#>  4 australiensis      0.002 96       Paratya   Crus… Adults     Acute LC50      
#>  5 dubia              0.025 192      Ceriodap… Crus… Neonates   Chronic NOEC    
#>  6 magna              0.037 504      Daphnia   Crus… Neonates   Chronic NOEC    
#>  7 tritaeniorhynchus  0.143 24       Culex     Inse… Larvae     Acute LC50      
#>  8 sinensis           6     24       Anopheles Inse… Larvae     Acute LC50      
#>  9 laevis             0.69  96       Xenopus   Amph… Larvae     Acute LC50      
#> 10 rutilus capsicus   0.063 96       Rutilus   Fish  Juveniles  Acute LC50      
#> 11 molitrix           0.092 96       Hypophth… Fish  Juveniles  Acute LC50      
#> 12 huso               0.095 96       Huso      Fish  Juveniles  Acute LC50      
#> 13 niloticus          0.342 96       Oreochro… Fish  Larvae     Acute LC50      
#> 14 reticulata         0.943 96       Poecilia  Fish  Adults     Acute LC50      
#> 
#> $anzg_aluminium_marine
#> # A tibble: 18 × 6
#>    Species             Conc Duration Genus         Group      Toxicity_measure
#>    <chr>              <dbl> <chr>    <chr>         <chr>      <chr>           
#>  1 closterium            27 72       Ceratoneis    Diatom     Chronic IC10    
#>  2 polymorphus          610 72       Minutocellus  Diatom     Chronic IC10    
#>  3 tricornutum         2100 72       Phaeodactylum Diatom     Chronic IC10    
#>  4 sp.                 3200 72       Tetraselmis   Microalga  Chronic IC10    
#>  5 tertiolecta         1400 72       Dunaliella    Microalga  Chronic IC10    
#>  6 banksii             9800 72       Hormosira     Brown alga Chronic NOEC    
#>  7 radiata             6800 72       Ecklonia      Brown alga Chronic IC10    
#>  8 tuberculata        28000 72       Heliocidaris  Echinoderm Chronic NOEC    
#>  9 lividus               32 72       Paracentrotus Echinoderm Chronic NOEC    
#> 10 edulis plannulatus   250 72       Mytilus       Mollusc    Chronic EC10    
#> 11 echinata             410 72       Saccostrea    Mollusc    Chronic EC10    
#> 12 glomerata            100 72       Saccostrea    Mollusc    Chronic NOEC    
#> 13 lutea                640 72       Tisochrysis   Microalga  Chronic IC10    
#> 14 tenuis              1300 18       Acropora      Cnidarian  Chronic EC10    
#> 15 diaphana             817 336      Exaiptasia    Cnidarian  Chronic EC10    
#> 16 dorsatus             115 96       Nassarius     Mollusc    Chronic EC10    
#> 17 amphitrite           416 96       Amphibalanus  Crustacean Chronic EC10    
#> 18 variabilis           312 72       Coenobita     Crustacean Chronic EC10    
#> 
#> $anzg_ametryn_fresh
#> # A tibble: 8 × 6
#>   Species          Conc Duration Genus        Group      Toxicity_measure
#>   <chr>           <dbl> <chr>    <chr>        <chr>      <chr>           
#> 1 pyrenoidosa      0.06 96       Chlorella    Green alga Chronic EC50    
#> 2 sp.           2000    240      Chlorococcum Green alga Chronic EC50    
#> 3 sp.              7.2  72       Neochloris   Green alga Chronic EC50    
#> 4 sp.              4.8  72       Platymonas   Green alga Chronic EC50    
#> 5 quadricauda     30    96       Scenedesmus  Green alga Chronic EC50    
#> 6 capricornutum    1.14 168      Selenastrum  Green alga Chronic NOEL    
#> 7 gibba            2    168      Lemna        Macrophyte Chronic NOEL    
#> 8 amphoroides      5.2  72       Stauroneis   Diatom     Chronic EC50    
#> 
#> $anzg_ammonia_fresh
#> # A tibble: 40 × 6
#>    Species               Conc Duration Genus        Group      Toxicity_measure
#>    <chr>                <dbl> <chr>    <chr>        <chr>      <chr>           
#>  1 vulgaris             165   3        Chlorella    Microalga  Chronic EC10    
#>  2 subcapitata          560   3        Raphidocelis Microalga  Chronic EC10    
#>  3 felina                 1.2 30       Polycelis    Flatworm   Chronic NOEC    
#>  4 dubia                 42   7        Ceriodaphnia Cladoceran Chronic NOEC    
#>  5 magna                 21   21       Daphnia      Cladoceran Chronic NOEC    
#>  6 riparius              29   21       Chironomus   Insect     Chronic NOEC    
#>  7 humeralis              7.2 29       Coloburiscus Insect     Chronic NOEC    
#>  8 sp.                    3.2 29       Deleatidium  Insect     Chronic NOEC    
#>  9 azteca                 8.9 70       Hyalella     Amphipod   Chronic NOEC    
#> 10 denticulata sinensis  19   21       Neocardidina Shrimp     Chronic NOEC    
#> # ℹ 30 more rows
#> 
#> $anzg_bisphenol_a_fresh
#> # A tibble: 19 × 6
#>    Species        Conc Duration Genus        Group              Toxicity_measure
#>    <chr>         <dbl> <chr>    <chr>        <chr>              <chr>           
#>  1 laevis        500   90       Xenopus      Amphibian          Chronic NOEC    
#>  2 arenarum     1800   14       Rhinella     Amphibian          Chronic NOEC    
#>  3 magna         120   21       Daphnia      Crustacean         Chronic LC50    
#>  4 azteca        490   42       Hyalella     Crustacean         Chronic NOEC    
#>  5 rerio           4   90       Danio        Fish               Chronic LOEC    
#>  6 promelas       16   164      Pimephales   Fish               Chronic NOEC    
#>  7 latipes        60   44       Oryzias      Fish               Chronic NOEC    
#>  8 riparius      100   20       Chironomus   Insect             Chronic NOEC    
#>  9 gibba        7800   7        Lemna        Macrophyte         Chronic NOEC    
#> 10 gymnorhiza   7990   28       Bruguiera    Macrophyte         Chronic LC50    
#> 11 subcapitata  1360   4        Raphidocelis Microalga          Chronic EC10    
#> 12 braunii      4000   4        Chlorolobion Microalga          Chronic NOEC    
#> 13 calyciflorus 1800   2        Brachionus   Micro-invertebrate Chornic NOEC    
#> 14 trichium       36.4 5        Paramecium   Micro-organism     Chronic IC50    
#> 15 caudatum      492   5        Paramecium   Micro-organism     Chronic IC50    
#> 16 antipodarum    20   28       Potamopyrgus Mollusc            Chronic NOEC    
#> 17 cornuarietis   50   14       Marisa       Mollusc            Chronic NOEC    
#> 18 acuta         200   21       Physa        Mollusc            Chronic LOEC    
#> 19 sp.          1600   NA       Heteromyenia Sponge             Chronic NOEC    
#> 
#> $anzg_bisphenol_a_marine
#> # A tibble: 8 × 6
#>   Species          Conc Duration Genus              Group       Toxicity_measure
#>   <chr>           <dbl> <chr>    <chr>              <chr>       <chr>           
#> 1 cordatum       302    72       Prorocentrum       Dinoflagel… Chronic EC50    
#> 2 polykrikoides 3470    72       Margalefidinium    Dinoflagel… Chronic EC50    
#> 3 pulcherrimus    45.6  920      Hemicentrotus      Echinoderm  Chronic LOEC    
#> 4 lividus         38.8  0.5      Paracentrotus      Echinoderm  Acute EC50      
#> 5 purpuratus      45.3  96       Strongylocentrotus Echinoderm  Chronic EC50    
#> 6 diversicolor     0.19 96       Haliotis           Mollusc     Chronic EC5     
#> 7 japonicus       20    96       Tigriopus          Crustacean  Acute LC50      
#> 8 bahia          103    96       Americamysis       Crustacean  Acute LC50      
#> 
#> $anzg_boron_fresh
#> # A tibble: 21 × 3
#>    Species  Conc Species_Genus        
#>    <chr>   <dbl> <chr>                
#>  1 sp. A    17   auratus_Carassius    
#>  2 sp. B     6.6 azteca_Hyalella      
#>  3 sp. C     6.1 densa_Egeria         
#>  4 sp. D     1.4 disperma_Lemna       
#>  5 sp. E     5.6 dubia_Ceriodaphnia   
#>  6 sp. F    41   fowleri_Anaxyrus     
#>  7 sp. G     2.4 magna_Daphnia        
#>  8 sp. H     4   mrigala_Cirrhinus    
#>  9 sp. I     6.2 mykiss_Oncorhynchus  
#> 10 sp. J     4.9 ochreatus_Potamogeton
#> # ℹ 11 more rows
#> 
#> $anzg_chlorine_marine
#> # A tibble: 29 × 7
#>    Species       Conc Duration    Genus       Group  Life_stage Toxicity_measure
#>    <chr>        <dbl> <chr>       <chr>       <chr>  <chr>      <chr>           
#>  1 excentricus    6.4 0.003470833 Dendraster  Echin… Sperm      Acute EC50      
#>  2 plicatilis    90   0.020833333 Brachionus  Rotif… Not stated Acute LC50      
#>  3 virginica     23   4           Crassostrea Mollu… Larva      Acute LC50      
#>  4 tonsa         29   4           Acartia     Crust… Not stated Acute LC50      
#>  5 sp.          687   4           Pontogeneia Crust… Adult      Acute LC50      
#>  6 sp.          145   4           Anonyx      Crust… Adult      Acute LC50      
#>  7 americanus  2890   0.041666667 Homarus     Crust… Larva      Acute LC50      
#>  8 sp.          162   4           Neomysis    Crust… Adult      Acute LC50      
#>  9 bahia         68   4           Mysidopsis  Crust… Juvenile   Acute LC50      
#> 10 danae        178   4           Pandalus    Crust… Juvenile … Acute LC50      
#> # ℹ 19 more rows
#> 
#> $anzg_chromium_III_fresh
#> # A tibble: 13 × 6
#>    Species        Conc Duration Genus           Group      Toxicity_measure
#>    <chr>         <dbl> <chr>    <chr>           <chr>      <chr>           
#>  1 ambiguum       19   48       Spirostomum     Protozoa   Chronic EC50    
#>  2 subcapitata     3.4 72       Raphidocelis    Microalga  Chronic EC50    
#>  3 kessleri       10   72       Chlorella       Microalga  Chronic EC50    
#>  4 chlorelloides 557   72       Dictyosphaerium Microalga  Chronic EC50    
#>  5 calyciflorus   82   24       Brachionus      Rotifer    Acute LC50      
#>  6 quadridentata 128   24       Lecane          Rotifer    Acute LC50      
#>  7 magna         330   504      Daphnia         Crustacean Chronic EC16    
#>  8 similis       324   48       Daphnia         Crustacean Acute EC50      
#>  9 mykiss         48   1,728    Oncorhynchus    Fish       Chronic NOEC    
#> 10 reticulata    333   96       Poecilia        Fish       Acute LC50      
#> 11 auratus       410   96       Carassius       Fish       Acute LC50      
#> 12 promelas      507   96       Pimephales      Fish       Acute LC50      
#> 13 macrochirus   746   96       Lepomis         Fish       Acute LC50      
#> 
#> $anzg_copper_marine
#> # A tibble: 45 × 9
#>    Species       Conc Duration Genus       Group Life_stage Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr>       <chr> <chr>      <chr>  <chr>        
#>  1 punctulata    1.4  3        Entomoneis  Diat… Exponenti… Bacil… Population g…
#>  2 polymorphus   0.2  3        Minutocell… Diat… Exponenti… Bacil… Population g…
#>  3 closterium    3.3  3        Ceratoneis  Diat… Exponenti… Bacil… Population g…
#>  4 tricornutum   1    3        Phaeodacty… Diat… Exponenti… Bacil… Population b…
#>  5 huxleyi       8.5  3        Coccolithus Gold… Exponenti… Hapto… Population g…
#>  6 oceanica      1.3  3        Gephyrocap… Gold… Exponenti… Hapto… Population g…
#>  7 sulcata       0.84 3        Proteomonas Gold… Exponenti… Hapto… Population g…
#>  8 lutea         2.7  3        Tisochrysis Gold… Exponenti… Hapto… Population g…
#>  9 sp.         300    3        Cyanobium   Cyan… Exponenti… Cyano… Population a…
#> 10 tertiolecta   8    3        Dunaliella  Gree… Exponenti… Chlor… Population g…
#> # ℹ 35 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_dioxins_fresh
#> # A tibble: 8 × 9
#>   Species        Conc Duration Genus        Group Life_stage Notes Test_endpoint
#>   <chr>         <dbl> <chr>    <chr>        <chr> <chr>      <chr> <chr>        
#> 1 carpio     0.000024 132      Cyprinus     Fish  Adult      2,3,… Mortality    
#> 2 lucius     0.0001   15       Esox         Fish  Egg        2,3,… Mortality    
#> 3 kisutch    0.00056  64       Oncorhynchus Fish  Juvenile   2,3,… Mortality    
#> 4 mykiss     0.000015 56       Oncorhynchus Fish  Fry        2,3,… Growth       
#> 5 latipes    0.0025   11       Oryzias      Fish  Embryo     2,3,… Mortality    
#> 6 promelas   0.00059  7        Pimephales   Fish  Embryo     2,3,… Mortality    
#> 7 fontinalis 0.0009   82       Salvelinus   Fish  Egg        2,3,… Mortality    
#> 8 namaycush  0.00125  92       Salvelinus   Fish  Egg        2,3,… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_diuron_fresh
#> # A tibble: 16 × 8
#>    Species                    Conc Duration Genus Group Life_stage Test_endpoint
#>    <chr>                     <dbl> <chr>    <chr> <chr> <chr>      <chr>        
#>  1 minutissimum              10.3  4        Achn… Diat… Planktoni… Growth rate  
#>  2 accomoda                 315    4        Crat… Diat… Planktoni… Growth rate  
#>  3 meneghiniana               4.9  4        Cycl… Diat… Planktoni… Growth rate  
#>  4 silesiacum                10.4  4        Ency… Diat… Planktoni… Growth rate  
#>  5 minima                  1886    4        Eoli… Diat… Planktoni… Growth rate  
#>  6 capucina var. vaucheri…    0.54 4        Frag… Diat… Planktoni… Growth rate  
#>  7 rumpens                    7.43 4        Frag… Diat… Planktoni… Growth rate  
#>  8 ulna                      17.6  4        Frag… Diat… Planktoni… Growth rate  
#>  9 parvulum                 365    4        Gomp… Diat… Planktoni… Growth rate  
#> 10 fossalis                  86.5  4        Maya… Diat… Planktoni… Growth rate  
#> 11 pelliculosa                9.17 3        Navi… Diat… Not stated Biomass yiel…
#> 12 palea                    199    4        Nitz… Diat… Planktoni… Growth rate  
#> 13 subspicatus                2.3  3        Scen… Gree… Not stated Biomass yiel…
#> 14 capricornutum              0.44 4        Sele… Gree… Not stated Biomass yiel…
#> 15 gibba                      2.49 7        Lemna Macr… Not stated Frond number…
#> 16 leopoliensis               1.14 3        Syne… Cyan… Not stated Biomass yiel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_diuron_marine
#> # A tibble: 12 × 8
#>    Species   Conc Duration Genus Group Life_stage Test_endpoint Toxicity_measure
#>    <chr>    <dbl> <chr>    <chr> <chr> <chr>      <chr>         <chr>           
#>  1 muelleri  1.5  3        Chae… Diat… Exponenti… Specific gro… Chronic NEC     
#>  2 punctul…  2    3        Ento… Diat… Not stated Cell density  Chronic NOEC    
#>  3 closter…  2    3        Nitz… Diat… Not stated Cell density  Chronic NOEC    
#>  4 pyrifor…  2.2  3        Neph… Gree… Not stated Cell density  Chronic EC10    
#>  5 sp.       1.64 3        Tetr… Gree… Exponenti… Specific gro… Chronic EC10    
#>  6 salina    1.7  3        Rhod… Cryp… Exponenti… Specific gro… Chronic NEC     
#>  7 goreaui   2.5  14       Clad… Dino… Exponenti… Specific gro… Chronic EC10    
#>  8 huxleyi   0.54 3        Emil… Gold… Exponenti… Cell density  Chronic NOEC    
#>  9 galbana   1.09 3        Isoc… Gold… Not stated Cell density  Chronic EC10    
#> 10 lutea     0.6  3        Tiso… Gold… Exponenti… Specific gro… Chronic EC10    
#> 11 japonica  2.3  15       Sacc… Brow… Thalli     Fresh weight  Chronic EC10    
#> 12 marina    2.5  10       Zost… Macr… Not stated Biomass (old… Chronic NOEC    
#> 
#> $anzg_fipronil_fresh
#> # A tibble: 13 × 10
#>    Species       Conc Duration Genus Group Life_stage Notes Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr> <chr> <chr>      <chr> <chr>  <chr>        
#>  1 brevilineata 0.015 2        Cheu… Inse… Larvae     Acut… Arthr… Mortality    
#>  2 vittatum     0.023 2        Simu… Inse… Larvae     Acut… Arthr… Mortality    
#>  3 quinquefasc… 0.035 1        Culex Inse… Larvae     Acut… Arthr… Mortality    
#>  4 crassicauda… 0.042 2        Chir… Inse… Larvae     Acut… Arthr… Mortality    
#>  5 paripes      0.042 2        Glyp… Inse… Larvae     Acut… Arthr… Mortality    
#>  6 taeniorhync… 0.043 2        Aedes Inse… Larvae     Acut… Arthr… Mortality    
#>  7 quadrimacul… 0.043 2        Anop… Inse… Larvae     Acut… Arthr… Mortality    
#>  8 sp.          0.044 4        Hexa… Inse… Nymph      Acut… Arthr… Mortality    
#>  9 nigripalpus  0.087 2        Culex Inse… Larvae     Acut… Arthr… Mortality    
#> 10 nubiferum    0.1   2        Poly… Inse… Larvae     Acut… Arthr… Mortality    
#> 11 aegypti      0.12  1        Aedes Inse… Larvae     Acut… Arthr… Mortality    
#> 12 annularius   0.245 2        Chir… Inse… Larvae     Acut… Arthr… Mortality    
#> 13 albopictus   0.81  2        Aedes Inse… Larvae     Acut… Arthr… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_fluoride_fresh
#> # A tibble: 22 × 9
#>    Species       Conc Duration Genus        Group Life_stage Notes Test_endpoint
#>    <chr>        <dbl> <chr>    <chr>        <chr> <chr>      <chr> <chr>        
#>  1 vulgaris        95 15       Chlorella    Gree… Not stated Valu… Growth       
#>  2 quadricauda     50 6.3      Scenedesmus  Gree… Not stated Valu… Growth       
#>  3 subspicata     127 3        Scenedesmus  Gree… Not stated Valu… Growth       
#>  4 subcapitata    195 3        Raphidocelis Gree… Not stated Valu… Growth       
#>  5 braunii         50 6.3      Ankistrodes… Gree… Not stated Valu… Growth       
#>  6 pyriformis      50 6.3      Nephroselmis Gree… Not stated Valu… Growth       
#>  7 meneghiniana    50 6.3      Cyclotella   Diat… Not stated Valu… Growth       
#>  8 minutus         50 6.3      Stephanodis… Diat… Not stated Valu… Growth       
#>  9 limnetica       50 6.3      Oscillatoria Cyan… Not stated Valu… Growth       
#> 10 leopoliensis    25 6.3      Synechococc… Cyan… Not stated Valu… Growth       
#> # ℹ 12 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_glyphosate_fresh
#> # A tibble: 15 × 9
#>    Species          Conc Duration Genus    Group Life_stage Phylum Test_endpoint
#>    <chr>           <dbl> <chr>    <chr>    <chr> <chr>      <chr>  <chr>        
#>  1 flosaquae       12000 5        Anabaena Blue… Not stated Cyano… Biomass yiel…
#>  2 dubia           65000 7        Cerioda… Crus… <24-hour … Arthr… Survival     
#>  3 quadricarinatus 22500 50       Cherax   Crus… Advanced … Arthr… Growth       
#>  4 saccharophila    1082 3        Chlorel… Gree… Exponenti… Chlor… Cell density 
#>  5 magna             450 21       Daphnia  Crus… Neonate    Arthr… Reproduction 
#>  6 azteca          19145 14       Hyalella Amph… Juvenile   Arthr… Survival     
#>  7 siliquoidea     12500 21       Lampsil… Biva… Juvenile   Mollu… Shell length 
#>  8 gibba            1400 14       Lemna    Macr… Not stated Trach… Frond number…
#>  9 minor            3780 7        Lemna    Macr… Not stated Trach… Chlorophyll-…
#> 10 pelliculosa      1800 5        Navicula Diat… Not stated Bacil… Biomass yiel…
#> 11 columella         316 12       Pseudos… Gast… Embryo     Mollu… Hatching suc…
#> 12 acutus           2000 4        Scenede… Gree… Not stated Chlor… Chlorophyll-…
#> 13 quadricauda       770 4        Scenede… Gree… Not stated Chlor… Chlorophyll-…
#> 14 subspicatus       400 3        Scenede… Gree… Exponenti… Chlor… Cell density 
#> 15 capricornutum   10000 5        Selenas… Gree… Not stated Chlor… Chlorophyll-…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_iron_fresh
#> # A tibble: 20 × 8
#>    Species   Conc Duration Genus Group Life_stage Test_endpoint Toxicity_measure
#>    <chr>    <dbl> <chr>    <chr> <chr> <chr>      <chr>         <chr>           
#>  1 acumina…  6900 21       Alat… Fung… NR         Growth        Chronic NOEC    
#>  2 tetracl…  6900 21       Arti… Fung… NR         Growth        Chronic NOEC    
#>  3 elegans   6900 21       Tetr… Fung… NR         Growth        Chronic NOEC    
#>  4 subcapi…   442 3        Raph… Micr… Not stated Yield         Chronic EC10    
#>  5 austral…  1000 64       Phra… Macr… Seedling   Growth        Chronic NOEC    
#>  6 dilatata   957 5        Euch… Roti… Neonate    Reproduction  Chronic LC10    
#>  7 variega…   470 35       Lumb… Anne… Worm       Reproduction  Chronic EC10    
#>  8 dorotoc… 40000 30       Duge… Plan… Not stated Growth        Chronic EC10    
#>  9 limbata   7863 30       Hexa… Inse… Nymph      Survival      Chronic EC10    
#> 10 margina… 50000 30       Lept… Inse… Larvae     Immobility    Chronic NOEC    
#> 11 dubia      383 7        Ceri… Crus… Neonate    Reproduction  Chronic EC10    
#> 12 magna     4380 21       Daph… Crus… Neonate    Reproduction  Chronic EC16    
#> 13 pulex      852 21       Daph… Crus… Neonate    Reproduction  Chronic NOEC    
#> 14 boreas    2607 35       Bufo  Amph… Tadpole    Biomass       Chronic EC10    
#> 15 kisutch   3040 7        Onco… Fish  Larvae     Mortality     Chronic NOECâ†’…
#> 16 latipes  25000 7        Oryz… Fish  Larvae     Mortality     Chronic NOEC    
#> 17 promelas   192 7        Pime… Fish  Larvae     Growth        Chronic EC10    
#> 18 william…   868 78       Pros… Fish  Egg        Biomass       Chronic EC10    
#> 19 trutta    5000 79       Salmo Fish  Egg        Biomass       Chronic EC20    
#> 20 fontina… 10280 245      Salv… Fish  3 months   Growth        Chronic NOEC    
#> 
#> $anzg_iron_marine
#> # A tibble: 16 × 8
#>    Species   Conc Duration Genus Group Life_stage Test_endpoint Toxicity_measure
#>    <chr>    <dbl> <chr>    <chr> <chr> <chr>      <chr>         <chr>           
#>  1 galbana  50000 4        Isoc… Micr… Not appli… Growth rate … Chronic NOEC    
#>  2 spathul… 18700 0.229    Acro… Cnid… Gametes    Fertilisation Chronic EC10    
#>  3 daedalea  2750 0.229    Plat… Cnid… Gametes    Fertilisation Chronic NOEC    
#>  4 tubercu…  2000 3        Heli… Echi… Embryo/la… Larval devel… Chronic NOEC    
#>  5 trapezia   935 2        Anad… Moll… Embryo     Abnormalities Chronic NEC     
#>  6 austral…   893 2        Barn… Moll… Embryo     Abnormalities Chronic NEC     
#>  7 tenuico…   806 2        Fulv… Moll… Embryo     Abnormalities Chronic NEC     
#>  8 alba       810 2        Hiat… Moll… Embryo     Abnormalities Chronic NEC     
#>  9 crenatus  1020 2        Irus  Moll… Embryo     Abnormalities Chronic NEC     
#> 10 gigas      724 2        Maga… Moll… Embryo     Abnormalities Chronic NEC     
#> 11 glomera…   738 2        Sacc… Moll… Embryo     Abnormalities Chronic NEC     
#> 12 livida    1270 2        Scae… Moll… Embryo     Abnormalities Chronic NEC     
#> 13 trigone…   948 2        Spis… Moll… Embryo     Abnormalities Chronic NEC     
#> 14 securis    896 2        Xeno… Moll… Embryo     Abnormalities Chronic NEC     
#> 15 rubra     4360 2        Hali… Moll… Embryoâ€“… Normal devel… Chronic EC10    
#> 16 anthonyi  1000 7        Canc… Crus… Embryo     Hatching      Chronic NOEC    
#> 
#> $anzg_mancozeb_fresh
#> # A tibble: 8 × 9
#>   Species        Conc Duration Genus       Group Life_stage Phylum Test_endpoint
#>   <chr>         <dbl> <chr>    <chr>       <chr> <chr>      <chr>  <chr>        
#> 1 pyrenoidosa   20    4        Chlorella   Micr… Not stated Chlor… Growth       
#> 2 vulgaris     100    4        Chlorella   Micr… Not stated Chlor… Growth       
#> 3 quadricauda  100    4        Scenedesmus Micr… Not stated Chlor… Growth       
#> 4 subcapitata  100    4        Raphidocel… Micr… Not stated Chlor… Growth       
#> 5 obliquus     500    4        Scenedesmus Micr… Not stated Chlor… Growth       
#> 6 magna          7    21       Daphnia     Crus… Neonate    Arthr… Reproduction 
#> 7 dilutus     2100    10       Chironomus  Inse… Larvae     Arthr… Survival     
#> 8 promelas       1.35 215      Pimephales  Fish  Larvae     Chord… Growth       
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_manganese_marine
#> # A tibble: 18 × 9
#>    Species        Conc Duration Genus      Group Life_stage Phylum Test_endpoint
#>    <chr>         <dbl> <chr>    <chr>      <chr> <chr>      <chr>  <chr>        
#>  1 closterium    18000 3        Ceratoneis Diat… N.A.       Bacil… Growth rate  
#>  2 lutea        125000 3        Isochrysis Gold… Log phase  Hapto… Growth rate  
#>  3 millepora      1090 14       Acropora   Cnid… Adult      Cnida… Tissue sloug…
#>  4 muricata        358 2        Acropora   Cnid… Adult      Cnida… Tissue sloug…
#>  5 spathulata      304 2        Acropora   Cnid… Adult      Cnida… Tissue sloug…
#>  6 daedalea      54000 0.229    Platygyra  Cnid… Gametes    Cnida… Fertilisation
#>  7 pistillata      374 2        Stylophora Cnid… Adult      Cnida… Tissue sloug…
#>  8 tuberculata    1580 3        Heliocida… Echi… Embryo     Echin… Embryo devel…
#>  9 trapezia       1040 2        Anadara    Moll… Embryo     Mollu… Embryo devel…
#> 10 australasiae   1780 2        Barnea     Moll… Embryo     Mollu… Embryo devel…
#> 11 tenuicostata   1460 2        Fulvia     Moll… Embryo     Mollu… Embryo devel…
#> 12 alba           1520 2        Hiatula    Moll… Embryo     Mollu… Embryo devel…
#> 13 crenatus       2410 2        Irus       Moll… Embryo     Mollu… Embryo devel…
#> 14 gigas           650 2        Magallana  Moll… Embryo     Mollu… Embryo devel…
#> 15 glomerata       654 2        Saccostrea Moll… Embryo     Mollu… Embryo devel…
#> 16 livida          959 2        Scaeochla… Moll… Embryo     Mollu… Embryo devel…
#> 17 trigonella     2090 2        Spisula    Moll… Embryo     Mollu… Embryo devel…
#> 18 securis         755 2        Xenostrob… Moll… Embryo     Mollu… Embryo devel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_mcpa_fresh
#> # A tibble: 16 × 9
#>    Species           Conc Duration Genus   Group Life_stage Phylum Test_endpoint
#>    <chr>            <dbl> <chr>    <chr>   <chr> <chr>      <chr>  <chr>        
#>  1 subcapitata       32   4        Raphid… Gree… Not stated Chlor… Growth       
#>  2 quadricauda    17020   20       Scened… Gree… Not stated Chlor… Growth       
#>  3 subspicatus   143000   3        Desmod… Gree… Not stated Chlor… Growth       
#>  4 flos-aquae       470   5        Anabae… Blue… Not stated Cyano… Growth       
#>  5 gibba             14   14       Lemna   Macr… Not stated Trach… Growth       
#>  6 minor            248   7        Lemna   Macr… Not stated Trach… Growth       
#>  7 pelliculosa        7.7 5        Navicu… Diat… Not stated Bacil… Growth       
#>  8 sp.               20   2        Gompho… Diat… Not stated Bacil… Growth       
#>  9 gracilis          20   2        Encyon… Diat… Not stated Bacil… Growth       
#> 10 ulna              20   2        Ulnaria Diat… Not stated Bacil… Growth       
#> 11 gracile          500   2        Gompho… Diat… Not stated Bacil… Growth       
#> 12 sp.              500   2        Cymbel… Diat… Not stated Bacil… Growth       
#> 13 minutissimum     500   2        Achnan… Diat… Not stated Bacil… Growth       
#> 14 cf. incisa       500   2        Eunotia Diat… Not stated Bacil… Growth       
#> 15 cryptotenella    500   2        Navicu… Diat… Not stated Bacil… Growth       
#> 16 magna          13000   21       Daphnia Crus… Neonate    Arthr… Immobilisati…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_metolachlor_fresh
#> # A tibble: 21 × 10
#>    Species       Conc Duration Genus Group Life_stage Notes Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr> <chr> <chr>      <chr> <chr>  <chr>        
#>  1 minutissimum  6528 4        Achn… Diat… Exponenti… Spec… Bacil… Cell density 
#>  2 flosaquae      240 5        Anab… Blue… Not stated NA    Cyano… Biomass yiel…
#>  3 demersum        14 14       Cera… Macr… Not stated Spec… Trach… Wet weight   
#>  4 reinhardtii    228 4        Chla… Gree… Not stated Spec… Chlor… Chlorophyll-…
#>  5 pyrenoidosa      1 4        Chlo… Gree… Exponenti… Spec… Chlor… Chlorophyll-…
#>  6 accomoda      4016 4        Crat… Diat… Exponenti… Spec… Bacil… Chlorophyll-…
#>  7 meneghiniana   925 4        Cycl… Diat… Exponenti… Spec… Bacil… Cell density 
#>  8 magna          224 21       Daph… Macr… <24 hour … NA    Arthr… Young per fe…
#>  9 canadensis     471 14       Elod… Macr… Not stated Spec… Trach… Wet weight   
#> 10 silesiacum    1048 4        Ency… Diat… Exponenti… Spec… Bacil… Chlorophyll-…
#> # ℹ 11 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_metsulfuron_methyl_fresh
#> # A tibble: 8 × 10
#>   Species        Conc Duration Genus Group Life_stage Notes Phylum Test_endpoint
#>   <chr>         <dbl> <chr>    <chr> <chr> <chr>      <chr> <chr>  <chr>        
#> 1 flos-aquae  9.54e+1 5        Anab… Blue… Not stated NA    Cyano… Biomass yiel…
#> 2 canadensis  5.4 e-2 8        Elod… Macr… Apical sh… Apic… Trach… Shoot length 
#> 3 gibba       1.93e-1 7        Lemna Macr… Not stated NA    Trach… Frond count  
#> 4 minor       1   e-1 42       Lemna Macr… Exponenti… NA    Trach… Frond count  
#> 5 spicatum    4   e-1 14       Myri… Macr… Apical sh… NA    Trach… Root occurre…
#> 6 pelliculosa 9.28e+4 4        Navi… Diat… Not stated NA    Bacil… Biomass yiel…
#> 7 mykiss      4.5 e+3 90       Onco… Fish  Early life NA    Chord… Mortality    
#> 8 subcapitata 1   e+1 5        Pseu… Gree… Not stated NA    Chlor… Biomass yiel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nickel_marine
#> # A tibble: 31 × 9
#>    Species        Conc Duration Genus      Group Life_stage Phylum Test_endpoint
#>    <chr>         <dbl> <chr>    <chr>      <chr> <chr>      <chr>  <chr>        
#>  1 sp.          3700   3        Cyanobium  Cyan… 6 x 10^3 … Cyano… Growth rate  
#>  2 closterium   2870   3        Ceratoneis Diat… 5-6 d old… Bacil… Growth rate  
#>  3 costatum      132   4        Skeletone… Diat… Not stated Bacil… Growth       
#>  4 tertiolecta 17900   4        Dunaliella Gree… Not stated Chlor… Growth       
#>  5 lutea         250   3        Isochrysis Brow… 5-6 d old… Hapto… Growth rate  
#>  6 sp.           310   3        Symbiodin… Dino… 6-7 d old… Dinop… Growth rate  
#>  7 parvula       144   10       Champia    Red … Adult      Rhodo… Reproduction 
#>  8 pyrifera       96.7 10       Macrocyst… Brow… Zoospore   Phaeo… Reproduction 
#>  9 sinjiensis      5.5 3.33     Acartia    Crus… Egg        Arthr… Development  
#> 10 amphitrite     67   4        Amphibala… Crus… Nauplius   Arthr… Metamorphosis
#> # ℹ 21 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nitrate_hard_fresh
#> # A tibble: 12 × 9
#>    Species             Conc Duration Genus Group Life_stage Phylum Test_endpoint
#>    <chr>              <dbl> <chr>    <chr> <chr> <chr>      <chr>  <chr>        
#>  1 sp.               1600   3        Chlo… Micr… Exponenti… Chlor… Growth       
#>  2 solitaria         1700   3        Oocy… Micr… Exponenti… Chlor… Growth       
#>  3 viridissima        220   4        Hydra Cnid… Adult      Cnida… Population g…
#>  4 dilutus            120   10       Chir… Inse… Larvae     Arthr… Growth weight
#>  5 dubia               28.5 7        Ceri… Crus… Neonates   Arthr… Reproduction 
#>  6 magna              358   7        Daph… Crus… Neonates   Arthr… Reproduction 
#>  7 azteca             102   14       Hyal… Crus… Juvenile   Arthr… Growth weight
#>  8 heilongjiangensis   45   13       Simo… Crus… Neonates   Arthr… Reproduction 
#>  9 topeka             268   30       Notr… Fish  Juvenile   Chord… Growth       
#> 10 mykiss             335   42       Onco… Fish  Fry        Chord… Growth       
#> 11 promelas            46.7 32       Pime… Fish  Embryo la… Chord… Growth weight
#> 12 versicolor          47   52       Hyla  Amph… Juvenile   Chord… Metamorphosis
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nitrate_moderate_fresh
#> # A tibble: 11 × 9
#>    Species      Conc Duration Genus        Group Life_stage Phylum Test_endpoint
#>    <chr>       <dbl> <chr>    <chr>        <chr> <chr>      <chr>  <chr>        
#>  1 siliquoidea  17   28       Lampsilis    Moll… Juvenile   Mollu… Weight       
#>  2 dilutus       5.8 10       Chironomus   Inse… Larva      Arthr… Growth weight
#>  3 sp.          20.3 20       Deleatidium  Inse… Larva      Arthr… Mortality    
#>  4 dubia        19.4 7        Ceriodaphnia Crus… Neonates   Arthr… Reproduction 
#>  5 azteca       11   42       Hyalella     Crus… Juvenile   Arthr… Growth weight
#>  6 rerio       200   29       Danio        Fish  Juvenile   Chord… Mortality an…
#>  7 maculatus    26.6 40       Galaxias     Fish  Juvenile   Chord… Mortality    
#>  8 cotidianus   24.9 21       Gobiomorphus Fish  Juvenile   Chord… Mortality    
#>  9 mykiss      120   42       Oncorhynchus Fish  Fry        Chord… Yolk develop…
#> 10 promelas      6.6 7        Pimephales   Fish  Embryo la… Chord… Growth weight
#> 11 regilla      56.7 10       Pseudacris   Amph… Embryo     Chord… Length       
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nitrate_soft_fresh
#> # A tibble: 14 × 9
#>    Species         Conc Duration Genus     Group Life_stage Phylum Test_endpoint
#>    <chr>          <dbl> <chr>    <chr>     <chr> <chr>      <chr>  <chr>        
#>  1 subcapitata    247   3        Raphidoc… Micr… Exponenti… Chlor… Growth       
#>  2 novaezelandiae   8.6 60       Sphaerium Moll… Juvenile   Mollu… Mortality    
#>  3 antipodarum      1.4 40       Potamopy… Moll… Juvenile   Mollu… Growth length
#>  4 planifrons       2.2 60       Paraneph… Crus… Juvenile   Arthr… Growth length
#>  5 clupeaformis     6.3 126      Coregonus Fish  Embryo al… Chord… Development  
#>  6 maculatus        2   40       Galaxias  Fish  Juvenile   Chord… Mortality    
#>  7 cotidianus      22.5 21       Gobiomor… Fish  Juvenile   Chord… Growth weight
#>  8 mykiss           2.2 30       Oncorhyn… Fish  Fry        Chord… Mortality    
#>  9 tshawytscha      2.3 30       Oncorhyn… Fish  Fry        Chord… Mortality    
#> 10 promelas        52   7        Pimephal… Fish  Embryo la… Chord… Growth weight
#> 11 clarkii          4.5 30       Salmo     Fish  Fry        Chord… Mortality    
#> 12 namaycush        1.6 146      Salvelin… Fish  Embryo al… Chord… Growth weight
#> 13 aurora         117   16       Rana      Amph… Embryo la… Chord… Growth weight
#> 14 laevis          24.8 10       Xenopus   Amph… Tadpole    Chord… Growth weight
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_paraquat_fresh
#> # A tibble: 10 × 9
#>    Species       Conc Duration Genus       Group Life_stage Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr>       <chr> <chr>      <chr>  <chr>        
#>  1 cf. chalybea   2.6 4        Oscillator… Cyan… Not stated Cyano… Growth       
#>  2 subcapitata  114   4        Raphidocel… Gree… Not stated Chlor… Growth       
#>  3 minor          5.1 4        Lemna       Macr… Not stated Trach… Growth       
#>  4 gibba          1   28       Lemna       Macr… Not stated Trach… Growth       
#>  5 paucicostata  31.8 7        Lemna       Macr… Not stated Trach… Growth       
#>  6 sp.           15.2 2        Mesocyclops Crus… Nauplii    Arthr… Mortality    
#>  7 aspericornis  20.7 2        Mesocyclops Crus… Nauplii    Arthr… Mortality    
#>  8 magna        125   2        Daphnia     Crus… Neonates   Arthr… Immobilisati…
#>  9 mykiss         8.4 1        Oncorhynch… Fish  Juveniles  Chord… Mortality    
#> 10 laevis        13.8 5        Xenopus     Amph… Embryo     Chord… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_perfluorooctane_sulfonate_pfos_fresh
#> # A tibble: 37 × 9
#>    Species             Conc Duration Genus Group Life_stage Phylum Test_endpoint
#>    <chr>              <dbl> <chr>    <chr> <chr> <chr>      <chr>  <chr>        
#>  1 gargarizans       2000   30       Bufo  Amph… Tadpole    Chord… Mortality    
#>  2 catesbeiana         57.6 72       Lith… Amph… Tadpole    Chord… Growth       
#>  3 pipiens             10   40       Lith… Amph… Tadpole    Chord… Development  
#>  4 laevis            1250   36       Xeno… Amph… Tadpole    Chord… Growth       
#>  5 tropicalis         590   150      Xeno… Amph… Embryo     Chord… Growth       
#>  6 flos-aquae       82000   4        Anab… Cyan… Not stated Cyano… Growth and b…
#>  7 dubia             6900   6        Ceri… Crus… Neonate    Arthr… Reproduction 
#>  8 diaptomus          400   28       Cycl… Crus… Not stated Arthr… Survival     
#>  9 canthocamptus s…  1000   35       Cycl… Crus… Not stated Arthr… Survival     
#> 10 carinata             0.4 21       Daph… Crus… Neonate    Arthr… Reproduction 
#> # ℹ 27 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_picloram_fresh
#> # A tibble: 12 × 9
#>    Species         Conc Duration Genus     Group Life_stage Phylum Test_endpoint
#>    <chr>          <dbl> <chr>    <chr>     <chr> <chr>      <chr>  <chr>        
#>  1 subcapitata     8944 4        Raphidoc… Micr… Not stated Chlor… Growth       
#>  2 vulgaris       10000 4        Chlorella Micr… Not stated Chlor… Growth       
#>  3 pseudolimnaeus  1650 4        Gammarus  Crus… Juvenile   Arthr… Mortality    
#>  4 fasciculatus    2700 4        Gammarus  Crus… Adult      Arthr… Mortality    
#>  5 magna          11800 21       Daphnia   Crus… Neonate    Arthr… Reproduction 
#>  6 californica     4800 10       Pteronar… Inse… YC-2       Arthr… Mortality    
#>  7 punctatus        140 4        Ictalurus Fish  Juvenile   Chord… Mortality    
#>  8 clarkii          229 4        Oncorhyn… Fish  Juvenile   Chord… Mortality    
#>  9 namaycush        236 4        Salvelin… Fish  Juvenile   Chord… Mortality    
#> 10 mykiss           550 60       Oncorhyn… Fish  Embryo     Chord… Growth       
#> 11 macrochirus     2226 4        Lepomis   Fish  Juvenile   Chord… Mortality    
#> 12 promelas        5530 4        Pimephal… Fish  Juvenile   Chord… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_simazine_fresh
#> # A tibble: 20 × 9
#>    Species       Conc Duration Genus       Group Life_stage Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr>       <chr> <chr>      <chr>  <chr>        
#>  1 magna       1000   21       Daphnia     Arth… Not stated Arthr… Mortality    
#>  2 pelliculosa   18   5        Navicula    Diat… Not stated Bacil… Cell density 
#>  3 geitleri     171   3        Chlamydomo… Gree… Exponenti… Chlor… Growth rate  
#>  4 pyrenoidosa   65   6        Chlorella   Gree… Not stated Chlor… Abundance    
#>  5 vulgaris     435   4        Chlorella   Gree… Not stated Chlor… Abundance    
#>  6 subcapitata   32   3        Pseudokirc… Gree… Not stated Chlor… Growth rate  
#>  7 obliquus      51.4 4        Scenedesmus Gree… Not stated Chlor… Growth rate  
#>  8 quadricauda   30   4        Scenedesmus Gree… Not stated Chlor… Abundance    
#>  9 auratus     1000   365      Carassius   Fish  Not stated Chord… Mortality    
#> 10 carpio        45   90       Cyprinus    Fish  Not stated Chord… Weight and m…
#> 11 macrochirus 1000   365      Lepomis     Fish  Not stated Chord… Mortality    
#> 12 mykiss       500   28       Oncorhynch… Fish  Not stated Chord… Mortality    
#> 13 promelas    1000   120      Pimephales  Fish  Early lif… Chord… Mortality    
#> 14 flos-aquae     7.2 5        Anabaena    Cyan… Not stated Cyano… Cell density 
#> 15 gramineus    100   7        Acorus      Macr… Not stated Trach… Fresh weight 
#> 16 gibba         28   14       Lemna       Macr… Not stated Trach… Biomass yield
#> 17 aquaticum     20   7        Myriophyll… Macr… 2 weeks o… Trach… Fresh weight 
#> 18 cordata      100   7        Pontederia  Macr… Not stated Trach… Fresh weight 
#> 19 latifolia    300   7        Typha       Macr… Not stated Trach… Fresh weight 
#> 20 americana     58   13       Vallisneria Macr… Not stated Trach… Length       
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_simazine_marine
#> # A tibble: 14 × 9
#>    Species         Conc Duration Genus     Group Life_stage Phylum Test_endpoint
#>    <chr>          <dbl> <chr>    <chr>     <chr> <chr>      <chr>  <chr>        
#>  1 closterium     310   3        Ceratone… Diat… Exponenti… Bacil… Growth rate  
#>  2 sp.            400   10       Chloroco… Gree… Not stated Chlor… Cell density 
#>  3 virginica     1000   7        Crassost… Biva… Spat       Mollu… Mortality an…
#>  4 goreaui        257   14       Cladocop… Dino… Exponenti… Dinof… Growth rate  
#>  5 tertiolecta   1000   10       Dunaliel… Gree… Not stated Chlor… Cell density 
#>  6 galbana        100   10       Isochrys… Gold… Not stated Hapto… Cell density 
#>  7 texana      100000   4        Neopanope Crus… Not stated Arthr… Mortality    
#>  8 kadiakensis  10000   2        Palaemon… Crus… Not stated Arthr… Mortality    
#>  9 duorarum     11300   4        Penaeus   Crus… Not stated Arthr… Mortality    
#> 10 tricornutum    100   3        Phaeodac… Diat… Exponenti… Bacil… Growth rate  
#> 11 salina          38.4 3        Rhodomon… Cryp… Exponenti… Crypt… Growth rate  
#> 12 costatum       250   5        Skeleton… Diat… Not stated Bacil… Cell density 
#> 13 sp.             37.5 3        Tetrasel… Gree… Exponenti… Chlor… Growth rate  
#> 14 lutea           60.2 3        Tisochry… Gold… Exponenti… Hapto… Growth rate  
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_sulfometuron_methyl_fresh
#> # A tibble: 6 × 9
#>   Species         Conc Duration Genus      Group Life_stage Phylum Test_endpoint
#>   <chr>          <dbl> <chr>    <chr>      <chr> <chr>      <chr>  <chr>        
#> 1 subcapitata    0.63  5        Raphidoce… Gree… Not stated Chlor… Growth       
#> 2 flos-aquae    14     5        Anabaena   Cyan… Not stated Cyano… Growth       
#> 3 pelliculosa  370     5        Navicula   Diat… Not stated Bacil… Growth       
#> 4 gibba          0.207 14       Lemna      Macr… Not stated Trach… Growth       
#> 5 magna       6100     21       Daphnia    Crus… Neonates   Arthr… Reproduction 
#> 6 laevis      1000     30       Xenopus    Amph… Embryos    Chord… Development  
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_zinc_marine
#> # A tibble: 16 × 9
#>    Species            Conc Duration Genus  Group Life_stage Phylum Test_endpoint
#>    <chr>             <dbl> <chr>    <chr>  <chr> <chr>      <chr>  <chr>        
#>  1 punctulata          153 2        Entom… Diat… Log phase  Ochro… Population g…
#>  2 closterium           84 3        Cerat… Diat… Log phase  Ochro… Population g…
#>  3 tertiolecta          54 3        Dunal… Gree… NR         Chlor… Mortality    
#>  4 fasiata             143 4        Ulva   Gree… Zoospores  Chlor… Growth and g…
#>  5 pyrifera           1070 16       Macro… Brow… Zoospores  Ochro… Reproduction 
#>  6 elegans              24 4        Hydro… Anne… Larvae     Annel… Development  
#>  7 pulchella             9 28       Aipta… Anem… Adult      Cnida… Reproduction 
#>  8 compressa            62 28       Allor… Crus… Juveniles  Arthr… Mortality    
#>  9 australiensis       230 14       Calli… Crus… Adult      Arthr… Immobilisati…
#> 10 gigas                24 2        Crass… Moll… Embryos    Mollu… Development  
#> 11 diversicolor         64 28       Halio… Moll… NR         Mollu… Growth       
#> 12 asperrima             5 2        Mimac… Moll… Larvae     Mollu… Development  
#> 13 edulis               35 2        Mytil… Moll… Eggs/Larv… Mollu… Development  
#> 14 galloprovincialis    36 2        Mytil… Moll… Embryos    Mollu… Development  
#> 15 trossulus            64 2        Mytil… Moll… Embryos    Mollu… Development  
#> 16 glomerata          2080 14       Sacco… Moll… Larvae     Mollu… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $ccme_boron
#> # A tibble: 28 × 6
#>    Species                  Conc Chemical Group        Units Medium    
#>    <chr>                   <dbl> <chr>    <fct>        <chr> <chr>     
#>  1 Oncorhynchus mykiss       2.1 Boron    Fish         mg/L  Freshwater
#>  2 Ictalurus punctatus       2.4 Boron    Fish         mg/L  Freshwater
#>  3 Micropterus salmoides     4.1 Boron    Fish         mg/L  Freshwater
#>  4 Brachydanio rerio        10   Boron    Fish         mg/L  Freshwater
#>  5 Carassius auratus        15.6 Boron    Fish         mg/L  Freshwater
#>  6 Pimephales promelas      18.3 Boron    Fish         mg/L  Freshwater
#>  7 Daphnia magna             6   Boron    Invertebrate mg/L  Freshwater
#>  8 Opercularia bimarginata  10   Boron    Invertebrate mg/L  Freshwater
#>  9 Ceriodaphnia dubia       13.4 Boron    Invertebrate mg/L  Freshwater
#> 10 Entosiphon sulcatum      15   Boron    Invertebrate mg/L  Freshwater
#> # ℹ 18 more rows
#> 
#> $ccme_cadmium
#> # A tibble: 36 × 6
#>    Species                   Conc Chemical Group Units Medium    
#>    <chr>                    <dbl> <chr>    <fct> <chr> <chr>     
#>  1 Oncorhynchus mykiss       0.23 Cadmium  Fish  ug/L  Freshwater
#>  2 Salvelinus confluentus    0.83 Cadmium  Fish  ug/L  Freshwater
#>  3 Cottus bairdi             0.96 Cadmium  Fish  ug/L  Freshwater
#>  4 Salmo salar               0.99 Cadmium  Fish  ug/L  Freshwater
#>  5 Acipenser transmontanus   1.14 Cadmium  Fish  ug/L  Freshwater
#>  6 Prosopium williamsoni     1.25 Cadmium  Fish  ug/L  Freshwater
#>  7 Salmo trutta              1.36 Cadmium  Fish  ug/L  Freshwater
#>  8 Salvelinus fontinalis     2.23 Cadmium  Fish  ug/L  Freshwater
#>  9 Oncorhynchus tshawytscha  2.29 Cadmium  Fish  ug/L  Freshwater
#> 10 Pimephales promelas       2.36 Cadmium  Fish  ug/L  Freshwater
#> # ℹ 26 more rows
#> 
#> $ccme_chloride
#> # A tibble: 28 × 6
#>    Species                       Conc Chemical Group        Units Medium    
#>    <chr>                        <dbl> <chr>    <fct>        <chr> <chr>     
#>  1 Pimephales promelas            598 Chloride Fish         mg/L  Freshwater
#>  2 Salmo trutta fario             607 Chloride Fish         mg/L  Freshwater
#>  3 Oncorhynchus mykiss            989 Chloride Fish         mg/L  Freshwater
#>  4 Xenopus laevis                1307 Chloride Amphibian    mg/L  Freshwater
#>  5 Rana pipiens                  3431 Chloride Amphibian    mg/L  Freshwater
#>  6 Lampsilis fasciola              24 Chloride Invertebrate mg/L  Freshwater
#>  7 Epioblasma torulosa rangiana    42 Chloride Invertebrate mg/L  Freshwater
#>  8 Musculium securis              121 Chloride Invertebrate mg/L  Freshwater
#>  9 Daphnia ambigua                259 Chloride Invertebrate mg/L  Freshwater
#> 10 Daphnia pulex                  368 Chloride Invertebrate mg/L  Freshwater
#> # ℹ 18 more rows
#> 
#> $ccme_endosulfan
#> # A tibble: 12 × 6
#>    Species                            Conc Chemical   Group        Units Medium 
#>    <chr>                             <dbl> <chr>      <fct>        <chr> <chr>  
#>  1 Oncorhynchus mykiss                0.05 Endosulfan Fish         ng/L  Freshw…
#>  2 Channa punctata                    0.24 Endosulfan Fish         ng/L  Freshw…
#>  3 Pimephales promelas                0.28 Endosulfan Fish         ng/L  Freshw…
#>  4 Hydra vulgaris                     0.06 Endosulfan Invertebrate ng/L  Freshw…
#>  5 Hydra viridissima                  0.07 Endosulfan Invertebrate ng/L  Freshw…
#>  6 Daphnia magna                     14.1  Endosulfan Invertebrate ng/L  Freshw…
#>  7 Ceriodaphnia dubia                14.1  Endosulfan Invertebrate ng/L  Freshw…
#>  8 Moinodaphnia macleayi             28.3  Endosulfan Invertebrate ng/L  Freshw…
#>  9 Daphnia cephalata                113.   Endosulfan Invertebrate ng/L  Freshw…
#> 10 Brachionus calyciflorus         1000    Endosulfan Invertebrate ng/L  Freshw…
#> 11 Pseudokirchneriella subcapitata  428.   Endosulfan Plant        ng/L  Freshw…
#> 12 Scenedesmus subspicatus          560    Endosulfan Plant        ng/L  Freshw…
#> 
#> $ccme_glyphosate
#> # A tibble: 18 × 6
#>    Species                           Conc Chemical   Group        Units Medium  
#>    <chr>                            <dbl> <chr>      <fct>        <chr> <chr>   
#>  1 Oncorhynchus kisutch            130000 Glyphosate Fish         ug/L  Freshwa…
#>  2 Oncorhynchus mykiss             150000 Glyphosate Fish         ug/L  Freshwa…
#>  3 Pimephales promelas              25700 Glyphosate Fish         ug/L  Freshwa…
#>  4 Ceriodaphnia dubia               65000 Glyphosate Invertebrate ug/L  Freshwa…
#>  5 Daphnia magna                    10487 Glyphosate Invertebrate ug/L  Freshwa…
#>  6 Hyalella azteca                  20500 Glyphosate Invertebrate ug/L  Freshwa…
#>  7 Pseudosuccinea columella          3162 Glyphosate Invertebrate ug/L  Freshwa…
#>  8 Anabaena flosaquae               12000 Glyphosate Plant        ug/L  Freshwa…
#>  9 Chlorella pyrenoidosa             3530 Glyphosate Plant        ug/L  Freshwa…
#> 10 Chlorella vulgaris                4696 Glyphosate Plant        ug/L  Freshwa…
#> 11 Lemna gibba                       1587 Glyphosate Plant        ug/L  Freshwa…
#> 12 Myriophyllum sibiricum            1474 Glyphosate Plant        ug/L  Freshwa…
#> 13 Navicula pelliculosa              1800 Glyphosate Plant        ug/L  Freshwa…
#> 14 Potamogeton pectinatus            3162 Glyphosate Plant        ug/L  Freshwa…
#> 15 Pseudokirchneriella subcapitata  10000 Glyphosate Plant        ug/L  Freshwa…
#> 16 Scenedesmus acutus                2820 Glyphosate Plant        ug/L  Freshwa…
#> 17 Scenedesmus obliquus             55858 Glyphosate Plant        ug/L  Freshwa…
#> 18 Scenedesmus quadricauda           1090 Glyphosate Plant        ug/L  Freshwa…
#> 
#> $ccme_silver
#> # A tibble: 9 × 6
#>   Species                Conc Chemical Group        Units Medium    
#>   <chr>                 <dbl> <chr>    <fct>        <chr> <chr>     
#> 1 Oncorhynchus mykiss    0.24 Silver   Fish         ug/L  Freshwater
#> 2 Lemna gibba            0.63 Silver   Plant        ug/L  Freshwater
#> 3 Ceriodaphnia dubia     0.78 Silver   Invertebrate ug/L  Freshwater
#> 4 Pimephales promelas    0.83 Silver   Fish         ug/L  Freshwater
#> 5 Ictalurus punctatus    1.9  Silver   Fish         ug/L  Freshwater
#> 6 Daphnia magna          2.12 Silver   Invertebrate ug/L  Freshwater
#> 7 Hyalella azteca        4    Silver   Invertebrate ug/L  Freshwater
#> 8 Chironomus tentans    13    Silver   Invertebrate ug/L  Freshwater
#> 9 Micropterus salmoides 23    Silver   Fish         ug/L  Freshwater
#> 
#> $ccme_uranium
#> # A tibble: 13 × 6
#>    Species                          Conc Chemical Group        Units Medium    
#>    <chr>                           <dbl> <chr>    <fct>        <chr> <chr>     
#>  1 Oncorhynchus mykiss               350 Uranium  Fish         ug/L  Freshwater
#>  2 Pimephales promelas              1040 Uranium  Fish         ug/L  Freshwater
#>  3 Esox lucius                      2550 Uranium  Fish         ug/L  Freshwater
#>  4 Salvelinus namaycush            13400 Uranium  Fish         ug/L  Freshwater
#>  5 Catostomus commersoni           14300 Uranium  Fish         ug/L  Freshwater
#>  6 Hyalella azteca                    12 Uranium  Invertebrate ug/L  Freshwater
#>  7 Ceriodaphnia dubia                 73 Uranium  Invertebrate ug/L  Freshwater
#>  8 Simocephalus serrulatus           480 Uranium  Invertebrate ug/L  Freshwater
#>  9 Daphnia magna                     530 Uranium  Invertebrate ug/L  Freshwater
#> 10 Chironomus tentans                930 Uranium  Invertebrate ug/L  Freshwater
#> 11 Pseudokirchneriella subcapitata    40 Uranium  Plant        ug/L  Freshwater
#> 12 Lemna minor                      3100 Uranium  Plant        ug/L  Freshwater
#> 13 Cryptomonas erosa                 172 Uranium  Plant        ug/L  Freshwater
#> 
#> $csiro_chlorine_marine
#> # A tibble: 30 × 3
#>    Species  Conc Group   
#>    <chr>   <dbl> <chr>   
#>  1 sp. A      90 Rotifer 
#>  2 sp. B     687 Amphipod
#>  3 sp. C     145 Amphipod
#>  4 sp. D     178 Shrimp  
#>  5 sp. E    2890 Lobster 
#>  6 sp. F     162 Mysid   
#>  7 sp. G      90 Shrimp  
#>  8 sp. H     134 Shrimp  
#>  9 sp. I    1420 Crab    
#> 10 sp. J      54 Fish    
#> # ℹ 20 more rows
#> 
#> $csiro_cobalt_marine
#> # A tibble: 14 × 7
#>    Species         Conc Duration Group Life_stage Test_endpoint Toxicity_measure
#>    <chr>          <dbl> <chr>    <chr> <chr>      <chr>         <chr>           
#>  1 Skeletonema … 5.9 e2 72       Diat… Exponenti… EC10          Chronic         
#>  2 Nitzschia cl… 4.08e2 96       Diat… Exponenti… EC50          Chronic         
#>  3 Chaetoceros … 8.8 e2 96       Diat… Exponenti… EC50          Chronic         
#>  4 Dunaliella t… 1.20e4 96       Gree… Exponenti… EC10          Chronic         
#>  5 Platymonus s… 2.48e3 96       Gree… Exponenti… EC50          Chronic         
#>  6 Champia parv… 1.23e0 48       Red … Adult bra… EC10          Chronic         
#>  7 Neanthes are… 2.06e2 113 d    Anne… Post-emer… EC10          Chronic         
#>  8 Idotea balti… 2.76e3 52 d     Moll… Adult      LC50          Chronic         
#>  9 Crassostrea … 1.66e3 48       Moll… Larvae     EC10          Chronic         
#> 10 Mytilus sp.   9.68e2 48       Echi… Embryos    EC10          Chronic         
#> 11 Dendraster e… 1.79e3 72       Echi… Embryos    EC10          Chronic         
#> 12 Strongylocen… 4.2 e1 96       Cnid… Larvae     EC10          Chronic         
#> 13 Aiptasia pul… 3.18e4 28 d     Fish  Lacerate   EC10          Chronic         
#> 14 Cyprinodon v… 2   e3 28 d     Isop… Freshly f… EC10          Chronic         
#> 
#> $csiro_lead_marine
#> # A tibble: 16 × 7
#>    Species         Conc Duration Group Life_stage Test_endpoint Toxicity_measure
#>    <chr>          <dbl> <chr>    <chr> <chr>      <chr>         <chr>           
#>  1 Dunalliella …  252   4        Gree… Exponenti… IC10          Yield           
#>  2 Phaeodactylu… 1230   3        Diat… Exponenti… IC10          Growth rate     
#>  3 Skeletonema …   29.4 4        Diat… Exponenti… IC10          Yield           
#>  4 Champia parv…   11.9 2        Macr… NA         EC10          Reproduction    
#>  5 Tisbe battag…  397   18       Cope… Nauplii    EC10          Adult survival  
#>  6 Strongylocen…   46   3        Sea … Embryo     EC10          Abnormalities   
#>  7 Paracentrotu…  119   2        Sea … Embryo     EC10          Larval growth   
#>  8 Dendraster e…  250   3        Sea … Embryo     EC10          Growth          
#>  9 Heliocidarus…   10   3        Sea … Embryo     NOEC          Reproduction    
#> 10 Amercamysis …    7   30       Mysid Neonates   EC10          Time to first b…
#> 11 Mytilus gall…   51   2        Biva… Embryo     EC10          Abnormalities   
#> 12 Mytilus tros…   12.4 2        Biva… Embryo     EC10          Abnormalities   
#> 13 Crassostrea …  931   2        Biva… Embryo     EC10          Survival        
#> 14 Neanthes are…   96   126      Poly… Juvenile   EC10          Survival        
#> 15 Cyprinodon v…  230   28       Fish  Embryo     EC10          Dry weight      
#> 16 Atherinops a…   44.3 28       Fish  Larva      EC10          Mortality and g…
#> 
#> $csiro_nickel_fresh
#> # A tibble: 31 × 6
#>    Species                   Conc Domain    Group            Notes Test_endpoint
#>    <chr>                    <dbl> <chr>     <chr>            <chr> <chr>        
#>  1 Lymnaea stagnalis         1.4  temperate Mollusc (snail)  none  EC10         
#>  2 Ceriodaphnia dubia        1.52 temperate Crustacean (wat… geom… EC10/LOEC    
#>  3 Alona affinis             3.63 temperate Crustacean (wat… geom… LC50         
#>  4 Ceriodaphnia quadrangula  8.49 temperate Crustacean (wat… geom… EC10         
#>  5 Peracantha truncata      11.0  temperate Crustacean (wat… geom… EC10         
#>  6 Daphnia magna            12    temperate Crustacean (wat… geom… EC10         
#>  7 Ceriodaphnia pulchella   13.9  temperate Crustacean (wat… geom… EC10         
#>  8 Simocephalus vetulus     14.4  temperate Crustacean (wat… geom… EC10         
#>  9 Simocephalus serrulatus  17.6  temperate Crustacean (wat… geom… EC10         
#> 10 Navicula pelliculosa     36    temperate Microalga (diat… none  EC10         
#> # ℹ 21 more rows
#> 
ssd_data_sets(set = "v1")
#> $aims_aluminium_marine
#> # A tibble: 20 × 9
#>    Common             Conc Domain Life_stage Phylum Source Species Test_endpoint
#>    <chr>             <dbl> <chr>  <chr>      <chr>  <chr>  <chr>   <chr>        
#>  1 Diatom              610 Tempe… NA         Bacil… (Gill… Minuto… EC10         
#>  2 Diatom               80 Tempe… NA         Bacil… (Gill… Cerato… EC10         
#>  3 Diatom               18 Tempe… NA         Bacil… (Gill… Cerato… EC10         
#>  4 Diatom               27 Mixed  NA         Bacil… (Gill… Cerato… EC10         
#>  5 Diatom             2100 Tempe… NA         Bacil… (Gill… Phaeod… EC10         
#>  6 Green microalga    1400 Tempe… NA         Chlor… (Gold… Dunali… EC10         
#>  7 Green microalga    3200 Tempe… NA         Chlor… (Gold… Tetras… EC10         
#>  8 Kelp               6800 Tempe… Zoospore   Ochro… (Gold… Ecklon… EC10         
#>  9 Sea grape          9800 Tempe… Zygote     Ochro… (Gold… Hormos… NOEC         
#> 10 Blue mussel         250 Tempe… Embryo     Mollu… (Gold… Mytilu… EC10         
#> 11 Sydney rock oyst…   100 Tempe… Embryo     Mollu… (Wils… Saccos… NOEC         
#> 12 Black sea urchin  28000 Tempe… Embryo     Echin… (Gold… Helioc… NOEC         
#> 13 Diatom               14 Tropi… NA         Bacil… (Harf… Cerato… EC10         
#> 14 Golden microalga    640 Tropi… NA         Hapto… (Tren… Tisoch… EC10         
#> 15 Blacklip oyster     410 Tropi… Embryo     Mollu… (Gold… Saccro… EC10         
#> 16 Dog whelk           115 Tropi… Larva      Mollu… (Tren… Nassar… EC10         
#> 17 Australian land …   312 Tropi… Zoea       Crust… (van … Coenob… EC10         
#> 18 Striped acorn ba…   416 Tropi… Nauplius   Crust… (van … Amphib… EC10         
#> 19 Branching coral    1300 Tropi… Larva      Cnida… (Negr… Acropo… EC10         
#> 20 Glass anemone       817 Tropi… Adult      Cnida… (Tren… Exaipt… EC10         
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $aims_gallium_marine
#> # A tibble: 6 × 9
#>   Common              Conc Domain Life_stage Phylum Source Species Test_endpoint
#>   <chr>              <dbl> <chr>  <chr>      <chr>  <chr>  <chr>   <chr>        
#> 1 Diatom               860 Tropi… NA         Bacil… (Harf… Cerato… EC10         
#> 2 Golden microalga    6000 Tropi… NA         Hapto… (Tren… Tisoch… NOEC         
#> 3 Dog whelk           3800 Tropi… Larva      Mollu… (Tren… Nassar… EC10         
#> 4 Australian land h…  6010 Tropi… Zoea       Crust… (van … Coenob… EC10         
#> 5 Striped acorn bar…  5070 Tropi… Nauplius   Crust… (van … Amphib… EC10         
#> 6 Branching coral     1160 Tropi… Larva      Cnida… (Negr… Acropo… EC10         
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $aims_molybdenum_marine
#> # A tibble: 14 × 9
#>    Common             Conc Domain Life_stage Phylum Source Species Test_endpoint
#>    <chr>             <dbl> <chr>  <chr>      <chr>  <chr>  <chr>   <chr>        
#>  1 Green microalga  8.81e5 Tempe… NA         Chlor… (Heij… Dunali… EC10         
#>  2 Diatom           1.7 e5 Tempe… NA         Bacil… (Heij… Phaeod… EC10         
#>  3 Red alga         2.74e5 Tempe… Adult      Rhodo… (Heij… Cerami… EC10         
#>  4 Pacific oyster   1.17e6 Tempe… Embryo     Mollu… (Heij… Crasso… EC10         
#>  5 Blue mussel      4.4 e3 Tempe… Embryo     Mollu… (Morg… Mytilu… EC10         
#>  6 Copepod          7.96e3 Tempe… Embryo     Crust… (Heij… Acarti… EC10         
#>  7 Purple sea urch… 3.26e5 Tempe… Embryo     Echin… (Heij… Strong… EC10         
#>  8 Pacific sand do… 2.34e5 Tempe… Embryo     Echin… (Heij… Dendra… EC10         
#>  9 Golden microalga 9.5 e3 Tropi… NA         Hapto… (Tren… Tisoch… NOEC         
#> 10 Dog whelk        7   e3 Tropi… Larva      Mollu… (Tren… Nassar… NOEC         
#> 11 Australian land… 1   e4 Tropi… Zoea       Crust… (van … Coenob… NOEC         
#> 12 Striped acorn b… 9   e3 Tropi… Nauplius   Crust… (van … Amphib… NOEC         
#> 13 Mysid shrimp     1.16e5 Tropi… Larva      Crust… (Heij… Americ… NOEC         
#> 14 Sheepshead minn… 8.41e4 Tropi… Embryo     Chord… (Heij… Cyprin… EC10         
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anon_a
#> # A tibble: 18 × 3
#>    Chemical   Conc Medium 
#>    <chr>     <dbl> <chr>  
#>  1 a         500   Unknown
#>  2 a        1800   Unknown
#>  3 a         120   Unknown
#>  4 a         490   Unknown
#>  5 a           4   Unknown
#>  6 a          16   Unknown
#>  7 a        6250   Unknown
#>  8 a         100   Unknown
#>  9 a        7800   Unknown
#> 10 a        7990   Unknown
#> 11 a        1360   Unknown
#> 12 a        4000   Unknown
#> 13 a        1800   Unknown
#> 14 a          36.4 Unknown
#> 15 a         492   Unknown
#> 16 a          50   Unknown
#> 17 a         200   Unknown
#> 18 a        1600   Unknown
#> 
#> $anon_b
#> # A tibble: 10 × 3
#>    Chemical  Conc Medium 
#>    <chr>    <dbl> <chr>  
#>  1 b          1   Unknown
#>  2 b          2.6 Unknown
#>  3 b          5.1 Unknown
#>  4 b          8.4 Unknown
#>  5 b         13.8 Unknown
#>  6 b         15.2 Unknown
#>  7 b         20.7 Unknown
#>  8 b         31.8 Unknown
#>  9 b        114   Unknown
#> 10 b        125   Unknown
#> 
#> $anon_c
#> # A tibble: 16 × 3
#>    Chemical     Conc Medium 
#>    <chr>       <dbl> <chr>  
#>  1 c            32   Unknown
#>  2 c         17020   Unknown
#>  3 c        143000   Unknown
#>  4 c           470   Unknown
#>  5 c            14   Unknown
#>  6 c           248   Unknown
#>  7 c             7.7 Unknown
#>  8 c            20   Unknown
#>  9 c            20   Unknown
#> 10 c            20   Unknown
#> 11 c           500   Unknown
#> 12 c           500   Unknown
#> 13 c           500   Unknown
#> 14 c           500   Unknown
#> 15 c           500   Unknown
#> 16 c         13000   Unknown
#> 
#> $anon_d
#> # A tibble: 12 × 3
#>    Chemical  Conc Medium 
#>    <chr>    <dbl> <chr>  
#>  1 d         8944 Unknown
#>  2 d        10000 Unknown
#>  3 d         1650 Unknown
#>  4 d         2700 Unknown
#>  5 d        11800 Unknown
#>  6 d         4800 Unknown
#>  7 d          140 Unknown
#>  8 d          229 Unknown
#>  9 d          236 Unknown
#> 10 d          550 Unknown
#> 11 d         2226 Unknown
#> 12 d         5530 Unknown
#> 
#> $anon_e
#> # A tibble: 17 × 3
#>    Chemical    Conc Medium 
#>    <chr>      <dbl> <chr>  
#>  1 e           11.2 Unknown
#>  2 e           17   Unknown
#>  3 e            3.4 Unknown
#>  4 e            5.5 Unknown
#>  5 e           20   Unknown
#>  6 e         1376   Unknown
#>  7 e            0.8 Unknown
#>  8 e         8200   Unknown
#>  9 e         3000   Unknown
#> 10 e        29050   Unknown
#> 11 e        11290   Unknown
#> 12 e         7116   Unknown
#> 13 e        13000   Unknown
#> 14 e        16400   Unknown
#> 15 e        16280   Unknown
#> 16 e         7100   Unknown
#> 17 e          100   Unknown
#> 
#> $anzg_metolachlor_fresh
#> # A tibble: 21 × 10
#>     Conc Duration Genus      Group Life_stage Notes Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>      <chr> <chr>      <chr> <chr>  <chr>   <chr>        
#>  1  6528 4        Achnanthi… Diat… Exponenti… Spec… Bacil… minuti… Cell density 
#>  2   240 5        Anabaena   Blue… Not stated NA    Cyano… flosaq… Biomass yiel…
#>  3    14 14       Ceratophy… Macr… Not stated Spec… Trach… demers… Wet weight   
#>  4   228 4        Chlamydom… Gree… Not stated Spec… Chlor… reinha… Chlorophyll-…
#>  5     1 4        Chlorella  Gree… Exponenti… Spec… Chlor… pyreno… Chlorophyll-…
#>  6  4016 4        Craticula  Diat… Exponenti… Spec… Bacil… accomo… Chlorophyll-…
#>  7   925 4        Cyclotella Diat… Exponenti… Spec… Bacil… menegh… Cell density 
#>  8   224 21       Daphnia    Macr… <24 hour … NA    Arthr… magna   Young per fe…
#>  9   471 14       Elodea     Macr… Not stated Spec… Trach… canade… Wet weight   
#> 10  1048 4        Encyonema  Diat… Exponenti… Spec… Bacil… silesi… Chlorophyll-…
#> # ℹ 11 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $ccme_boron
#> # A tibble: 28 × 6
#>    Chemical Species                  Conc Group        Units Medium    
#>    <chr>    <chr>                   <dbl> <fct>        <chr> <chr>     
#>  1 Boron    Oncorhynchus mykiss       2.1 Fish         mg/L  Freshwater
#>  2 Boron    Ictalurus punctatus       2.4 Fish         mg/L  Freshwater
#>  3 Boron    Micropterus salmoides     4.1 Fish         mg/L  Freshwater
#>  4 Boron    Brachydanio rerio        10   Fish         mg/L  Freshwater
#>  5 Boron    Carassius auratus        15.6 Fish         mg/L  Freshwater
#>  6 Boron    Pimephales promelas      18.3 Fish         mg/L  Freshwater
#>  7 Boron    Daphnia magna             6   Invertebrate mg/L  Freshwater
#>  8 Boron    Opercularia bimarginata  10   Invertebrate mg/L  Freshwater
#>  9 Boron    Ceriodaphnia dubia       13.4 Invertebrate mg/L  Freshwater
#> 10 Boron    Entosiphon sulcatum      15   Invertebrate mg/L  Freshwater
#> # ℹ 18 more rows
#> 
#> $ccme_cadmium
#> # A tibble: 36 × 6
#>    Chemical Species                   Conc Group Units Medium    
#>    <chr>    <chr>                    <dbl> <fct> <chr> <chr>     
#>  1 Cadmium  Oncorhynchus mykiss       0.23 Fish  ug/L  Freshwater
#>  2 Cadmium  Salvelinus confluentus    0.83 Fish  ug/L  Freshwater
#>  3 Cadmium  Cottus bairdi             0.96 Fish  ug/L  Freshwater
#>  4 Cadmium  Salmo salar               0.99 Fish  ug/L  Freshwater
#>  5 Cadmium  Acipenser transmontanus   1.14 Fish  ug/L  Freshwater
#>  6 Cadmium  Prosopium williamsoni     1.25 Fish  ug/L  Freshwater
#>  7 Cadmium  Salmo trutta              1.36 Fish  ug/L  Freshwater
#>  8 Cadmium  Salvelinus fontinalis     2.23 Fish  ug/L  Freshwater
#>  9 Cadmium  Oncorhynchus tshawytscha  2.29 Fish  ug/L  Freshwater
#> 10 Cadmium  Pimephales promelas       2.36 Fish  ug/L  Freshwater
#> # ℹ 26 more rows
#> 
#> $ccme_chloride
#> # A tibble: 28 × 6
#>    Chemical Species                       Conc Group        Units Medium    
#>    <chr>    <chr>                        <dbl> <fct>        <chr> <chr>     
#>  1 Chloride Pimephales promelas            598 Fish         mg/L  Freshwater
#>  2 Chloride Salmo trutta fario             607 Fish         mg/L  Freshwater
#>  3 Chloride Oncorhynchus mykiss            989 Fish         mg/L  Freshwater
#>  4 Chloride Xenopus laevis                1307 Amphibian    mg/L  Freshwater
#>  5 Chloride Rana pipiens                  3431 Amphibian    mg/L  Freshwater
#>  6 Chloride Lampsilis fasciola              24 Invertebrate mg/L  Freshwater
#>  7 Chloride Epioblasma torulosa rangiana    42 Invertebrate mg/L  Freshwater
#>  8 Chloride Musculium securis              121 Invertebrate mg/L  Freshwater
#>  9 Chloride Daphnia ambigua                259 Invertebrate mg/L  Freshwater
#> 10 Chloride Daphnia pulex                  368 Invertebrate mg/L  Freshwater
#> # ℹ 18 more rows
#> 
#> $ccme_endosulfan
#> # A tibble: 12 × 6
#>    Chemical   Species                            Conc Group        Units Medium 
#>    <chr>      <chr>                             <dbl> <fct>        <chr> <chr>  
#>  1 Endosulfan Oncorhynchus mykiss                0.05 Fish         ng/L  Freshw…
#>  2 Endosulfan Channa punctata                    0.24 Fish         ng/L  Freshw…
#>  3 Endosulfan Pimephales promelas                0.28 Fish         ng/L  Freshw…
#>  4 Endosulfan Hydra vulgaris                     0.06 Invertebrate ng/L  Freshw…
#>  5 Endosulfan Hydra viridissima                  0.07 Invertebrate ng/L  Freshw…
#>  6 Endosulfan Daphnia magna                     14.1  Invertebrate ng/L  Freshw…
#>  7 Endosulfan Ceriodaphnia dubia                14.1  Invertebrate ng/L  Freshw…
#>  8 Endosulfan Moinodaphnia macleayi             28.3  Invertebrate ng/L  Freshw…
#>  9 Endosulfan Daphnia cephalata                113.   Invertebrate ng/L  Freshw…
#> 10 Endosulfan Brachionus calyciflorus         1000    Invertebrate ng/L  Freshw…
#> 11 Endosulfan Pseudokirchneriella subcapitata  428.   Plant        ng/L  Freshw…
#> 12 Endosulfan Scenedesmus subspicatus          560    Plant        ng/L  Freshw…
#> 
#> $ccme_glyphosate
#> # A tibble: 18 × 6
#>    Chemical   Species                           Conc Group        Units Medium  
#>    <chr>      <chr>                            <dbl> <fct>        <chr> <chr>   
#>  1 Glyphosate Oncorhynchus kisutch            130000 Fish         ug/L  Freshwa…
#>  2 Glyphosate Oncorhynchus mykiss             150000 Fish         ug/L  Freshwa…
#>  3 Glyphosate Pimephales promelas              25700 Fish         ug/L  Freshwa…
#>  4 Glyphosate Ceriodaphnia dubia               65000 Invertebrate ug/L  Freshwa…
#>  5 Glyphosate Daphnia magna                    10487 Invertebrate ug/L  Freshwa…
#>  6 Glyphosate Hyalella azteca                  20500 Invertebrate ug/L  Freshwa…
#>  7 Glyphosate Pseudosuccinea columella          3162 Invertebrate ug/L  Freshwa…
#>  8 Glyphosate Anabaena flosaquae               12000 Plant        ug/L  Freshwa…
#>  9 Glyphosate Chlorella pyrenoidosa             3530 Plant        ug/L  Freshwa…
#> 10 Glyphosate Chlorella vulgaris                4696 Plant        ug/L  Freshwa…
#> 11 Glyphosate Lemna gibba                       1587 Plant        ug/L  Freshwa…
#> 12 Glyphosate Myriophyllum sibiricum            1474 Plant        ug/L  Freshwa…
#> 13 Glyphosate Navicula pelliculosa              1800 Plant        ug/L  Freshwa…
#> 14 Glyphosate Potamogeton pectinatus            3162 Plant        ug/L  Freshwa…
#> 15 Glyphosate Pseudokirchneriella subcapitata  10000 Plant        ug/L  Freshwa…
#> 16 Glyphosate Scenedesmus acutus                2820 Plant        ug/L  Freshwa…
#> 17 Glyphosate Scenedesmus obliquus             55858 Plant        ug/L  Freshwa…
#> 18 Glyphosate Scenedesmus quadricauda           1090 Plant        ug/L  Freshwa…
#> 
#> $ccme_silver
#> # A tibble: 9 × 6
#>   Chemical Species                Conc Group        Units Medium    
#>   <chr>    <chr>                 <dbl> <fct>        <chr> <chr>     
#> 1 Silver   Oncorhynchus mykiss    0.24 Fish         ug/L  Freshwater
#> 2 Silver   Lemna gibba            0.63 Plant        ug/L  Freshwater
#> 3 Silver   Ceriodaphnia dubia     0.78 Invertebrate ug/L  Freshwater
#> 4 Silver   Pimephales promelas    0.83 Fish         ug/L  Freshwater
#> 5 Silver   Ictalurus punctatus    1.9  Fish         ug/L  Freshwater
#> 6 Silver   Daphnia magna          2.12 Invertebrate ug/L  Freshwater
#> 7 Silver   Hyalella azteca        4    Invertebrate ug/L  Freshwater
#> 8 Silver   Chironomus tentans    13    Invertebrate ug/L  Freshwater
#> 9 Silver   Micropterus salmoides 23    Fish         ug/L  Freshwater
#> 
#> $ccme_uranium
#> # A tibble: 13 × 6
#>    Chemical Species                          Conc Group        Units Medium    
#>    <chr>    <chr>                           <dbl> <fct>        <chr> <chr>     
#>  1 Uranium  Oncorhynchus mykiss               350 Fish         ug/L  Freshwater
#>  2 Uranium  Pimephales promelas              1040 Fish         ug/L  Freshwater
#>  3 Uranium  Esox lucius                      2550 Fish         ug/L  Freshwater
#>  4 Uranium  Salvelinus namaycush            13400 Fish         ug/L  Freshwater
#>  5 Uranium  Catostomus commersoni           14300 Fish         ug/L  Freshwater
#>  6 Uranium  Hyalella azteca                    12 Invertebrate ug/L  Freshwater
#>  7 Uranium  Ceriodaphnia dubia                 73 Invertebrate ug/L  Freshwater
#>  8 Uranium  Simocephalus serrulatus           480 Invertebrate ug/L  Freshwater
#>  9 Uranium  Daphnia magna                     530 Invertebrate ug/L  Freshwater
#> 10 Uranium  Chironomus tentans                930 Invertebrate ug/L  Freshwater
#> 11 Uranium  Pseudokirchneriella subcapitata    40 Plant        ug/L  Freshwater
#> 12 Uranium  Lemna minor                      3100 Plant        ug/L  Freshwater
#> 13 Uranium  Cryptomonas erosa                 172 Plant        ug/L  Freshwater
#> 
#> $csiro_chlorine_marine
#> # A tibble: 30 × 2
#>     Conc Group   
#>    <dbl> <chr>   
#>  1    90 Rotifer 
#>  2   687 Amphipod
#>  3   145 Amphipod
#>  4   178 Shrimp  
#>  5  2890 Lobster 
#>  6   162 Mysid   
#>  7    90 Shrimp  
#>  8   134 Shrimp  
#>  9  1420 Crab    
#> 10    54 Fish    
#> # ℹ 20 more rows
#> 
#> $csiro_cobalt_marine
#> # A tibble: 14 × 7
#>        Conc Duration Group     Life_stage Species Test_endpoint Toxicity_measure
#>       <dbl> <chr>    <chr>     <chr>      <chr>   <chr>         <chr>           
#>  1   590    72       Diatom    Exponenti… Skelet… EC10          Chronic         
#>  2   408    96       Diatom    Exponenti… Nitzsc… EC50          Chronic         
#>  3   880    96       Diatom    Exponenti… Chaeto… EC50          Chronic         
#>  4 12000    96       Green al… Exponenti… Dunali… EC10          Chronic         
#>  5  2480    96       Green al… Exponenti… Platym… EC50          Chronic         
#>  6     1.23 48       Red alga  Adult bra… Champi… EC10          Chronic         
#>  7   206    113 d    Annelid   Post-emer… Neanth… EC10          Chronic         
#>  8  2760    52 d     Mollusc   Adult      Idotea… LC50          Chronic         
#>  9  1660    48       Mollusc   Larvae     Crasso… EC10          Chronic         
#> 10   968    48       Echinode… Embryos    Mytilu… EC10          Chronic         
#> 11  1790    72       Echinode… Embryos    Dendra… EC10          Chronic         
#> 12    42    96       Cnidarian Larvae     Strong… EC10          Chronic         
#> 13 31800    28 d     Fish      Lacerate   Aiptas… EC10          Chronic         
#> 14  2000    28 d     Isopod    Freshly f… Cyprin… EC10          Chronic         
#> 
#> $csiro_lead_marine
#> # A tibble: 16 × 7
#>      Conc Duration Group      Life_stage  Species Test_endpoint Toxicity_measure
#>     <dbl> <chr>    <chr>      <chr>       <chr>   <chr>         <chr>           
#>  1  252   4        Green alga Exponentia… Dunall… IC10          Yield           
#>  2 1230   3        Diatom     Exponentia… Phaeod… IC10          Growth rate     
#>  3   29.4 4        Diatom     Exponentia… Skelet… IC10          Yield           
#>  4   11.9 2        Macroalga  NA          Champi… EC10          Reproduction    
#>  5  397   18       Copepod    Nauplii     Tisbe … EC10          Adult survival  
#>  6   46   3        Sea urchin Embryo      Strong… EC10          Abnormalities   
#>  7  119   2        Sea urchin Embryo      Parace… EC10          Larval growth   
#>  8  250   3        Sea urchin Embryo      Dendra… EC10          Growth          
#>  9   10   3        Sea urchin Embryo      Helioc… NOEC          Reproduction    
#> 10    7   30       Mysid      Neonates    Amerca… EC10          Time to first b…
#> 11   51   2        Bivalve    Embryo      Mytilu… EC10          Abnormalities   
#> 12   12.4 2        Bivalve    Embryo      Mytilu… EC10          Abnormalities   
#> 13  931   2        Bivalve    Embryo      Crasso… EC10          Survival        
#> 14   96   126      Polychaete Juvenile    Neanth… EC10          Survival        
#> 15  230   28       Fish       Embryo      Cyprin… EC10          Dry weight      
#> 16   44.3 28       Fish       Larva       Atheri… EC10          Mortality and g…
#> 
#> $csiro_nickel_fresh
#> # A tibble: 31 × 6
#>     Conc Domain    Group                   Notes   Species         Test_endpoint
#>    <dbl> <chr>     <chr>                   <chr>   <chr>           <chr>        
#>  1  1.4  temperate Mollusc (snail)         none    Lymnaea stagna… EC10         
#>  2  1.52 temperate Crustacean (water flea) geomean Ceriodaphnia d… EC10/LOEC    
#>  3  3.63 temperate Crustacean (water flea) geomean Alona affinis   LC50         
#>  4  8.49 temperate Crustacean (water flea) geomean Ceriodaphnia q… EC10         
#>  5 11.0  temperate Crustacean (water flea) geomean Peracantha tru… EC10         
#>  6 12    temperate Crustacean (water flea) geomean Daphnia magna   EC10         
#>  7 13.9  temperate Crustacean (water flea) geomean Ceriodaphnia p… EC10         
#>  8 14.4  temperate Crustacean (water flea) geomean Simocephalus v… EC10         
#>  9 17.6  temperate Crustacean (water flea) geomean Simocephalus s… EC10         
#> 10 36    temperate Microalga (diatom)      none    Navicula pelli… EC10         
#> # ℹ 21 more rows
#> 
ssd_data_sets(set = c("ccme", "anzg"))
#> Geometric mean applied to duplicate species rows in: anzg_boron_fresh.
#> $anzg_alpha_cypermethrin_fresh
#> # A tibble: 14 × 7
#>    Species             Conc Duration Genus     Group Life_stage Toxicity_measure
#>    <chr>              <dbl> <chr>    <chr>     <chr> <chr>      <chr>           
#>  1 flosaquae         27.2   96       Anabaena  Cyan… Not stated Chronic NOEC    
#>  2 pelliculosa       72     96       Navicula  Diat… Not stated Chronic NOEC    
#>  3 gibba              1.39  168      Lemna     Macr… Not stated Chronic NOEC    
#>  4 australiensis      0.002 96       Paratya   Crus… Adults     Acute LC50      
#>  5 dubia              0.025 192      Ceriodap… Crus… Neonates   Chronic NOEC    
#>  6 magna              0.037 504      Daphnia   Crus… Neonates   Chronic NOEC    
#>  7 tritaeniorhynchus  0.143 24       Culex     Inse… Larvae     Acute LC50      
#>  8 sinensis           6     24       Anopheles Inse… Larvae     Acute LC50      
#>  9 laevis             0.69  96       Xenopus   Amph… Larvae     Acute LC50      
#> 10 rutilus capsicus   0.063 96       Rutilus   Fish  Juveniles  Acute LC50      
#> 11 molitrix           0.092 96       Hypophth… Fish  Juveniles  Acute LC50      
#> 12 huso               0.095 96       Huso      Fish  Juveniles  Acute LC50      
#> 13 niloticus          0.342 96       Oreochro… Fish  Larvae     Acute LC50      
#> 14 reticulata         0.943 96       Poecilia  Fish  Adults     Acute LC50      
#> 
#> $anzg_aluminium_marine
#> # A tibble: 18 × 6
#>    Species             Conc Duration Genus         Group      Toxicity_measure
#>    <chr>              <dbl> <chr>    <chr>         <chr>      <chr>           
#>  1 closterium            27 72       Ceratoneis    Diatom     Chronic IC10    
#>  2 polymorphus          610 72       Minutocellus  Diatom     Chronic IC10    
#>  3 tricornutum         2100 72       Phaeodactylum Diatom     Chronic IC10    
#>  4 sp.                 3200 72       Tetraselmis   Microalga  Chronic IC10    
#>  5 tertiolecta         1400 72       Dunaliella    Microalga  Chronic IC10    
#>  6 banksii             9800 72       Hormosira     Brown alga Chronic NOEC    
#>  7 radiata             6800 72       Ecklonia      Brown alga Chronic IC10    
#>  8 tuberculata        28000 72       Heliocidaris  Echinoderm Chronic NOEC    
#>  9 lividus               32 72       Paracentrotus Echinoderm Chronic NOEC    
#> 10 edulis plannulatus   250 72       Mytilus       Mollusc    Chronic EC10    
#> 11 echinata             410 72       Saccostrea    Mollusc    Chronic EC10    
#> 12 glomerata            100 72       Saccostrea    Mollusc    Chronic NOEC    
#> 13 lutea                640 72       Tisochrysis   Microalga  Chronic IC10    
#> 14 tenuis              1300 18       Acropora      Cnidarian  Chronic EC10    
#> 15 diaphana             817 336      Exaiptasia    Cnidarian  Chronic EC10    
#> 16 dorsatus             115 96       Nassarius     Mollusc    Chronic EC10    
#> 17 amphitrite           416 96       Amphibalanus  Crustacean Chronic EC10    
#> 18 variabilis           312 72       Coenobita     Crustacean Chronic EC10    
#> 
#> $anzg_ametryn_fresh
#> # A tibble: 8 × 6
#>   Species          Conc Duration Genus        Group      Toxicity_measure
#>   <chr>           <dbl> <chr>    <chr>        <chr>      <chr>           
#> 1 pyrenoidosa      0.06 96       Chlorella    Green alga Chronic EC50    
#> 2 sp.           2000    240      Chlorococcum Green alga Chronic EC50    
#> 3 sp.              7.2  72       Neochloris   Green alga Chronic EC50    
#> 4 sp.              4.8  72       Platymonas   Green alga Chronic EC50    
#> 5 quadricauda     30    96       Scenedesmus  Green alga Chronic EC50    
#> 6 capricornutum    1.14 168      Selenastrum  Green alga Chronic NOEL    
#> 7 gibba            2    168      Lemna        Macrophyte Chronic NOEL    
#> 8 amphoroides      5.2  72       Stauroneis   Diatom     Chronic EC50    
#> 
#> $anzg_ammonia_fresh
#> # A tibble: 40 × 6
#>    Species               Conc Duration Genus        Group      Toxicity_measure
#>    <chr>                <dbl> <chr>    <chr>        <chr>      <chr>           
#>  1 vulgaris             165   3        Chlorella    Microalga  Chronic EC10    
#>  2 subcapitata          560   3        Raphidocelis Microalga  Chronic EC10    
#>  3 felina                 1.2 30       Polycelis    Flatworm   Chronic NOEC    
#>  4 dubia                 42   7        Ceriodaphnia Cladoceran Chronic NOEC    
#>  5 magna                 21   21       Daphnia      Cladoceran Chronic NOEC    
#>  6 riparius              29   21       Chironomus   Insect     Chronic NOEC    
#>  7 humeralis              7.2 29       Coloburiscus Insect     Chronic NOEC    
#>  8 sp.                    3.2 29       Deleatidium  Insect     Chronic NOEC    
#>  9 azteca                 8.9 70       Hyalella     Amphipod   Chronic NOEC    
#> 10 denticulata sinensis  19   21       Neocardidina Shrimp     Chronic NOEC    
#> # ℹ 30 more rows
#> 
#> $anzg_bisphenol_a_fresh
#> # A tibble: 19 × 6
#>    Species        Conc Duration Genus        Group              Toxicity_measure
#>    <chr>         <dbl> <chr>    <chr>        <chr>              <chr>           
#>  1 laevis        500   90       Xenopus      Amphibian          Chronic NOEC    
#>  2 arenarum     1800   14       Rhinella     Amphibian          Chronic NOEC    
#>  3 magna         120   21       Daphnia      Crustacean         Chronic LC50    
#>  4 azteca        490   42       Hyalella     Crustacean         Chronic NOEC    
#>  5 rerio           4   90       Danio        Fish               Chronic LOEC    
#>  6 promelas       16   164      Pimephales   Fish               Chronic NOEC    
#>  7 latipes        60   44       Oryzias      Fish               Chronic NOEC    
#>  8 riparius      100   20       Chironomus   Insect             Chronic NOEC    
#>  9 gibba        7800   7        Lemna        Macrophyte         Chronic NOEC    
#> 10 gymnorhiza   7990   28       Bruguiera    Macrophyte         Chronic LC50    
#> 11 subcapitata  1360   4        Raphidocelis Microalga          Chronic EC10    
#> 12 braunii      4000   4        Chlorolobion Microalga          Chronic NOEC    
#> 13 calyciflorus 1800   2        Brachionus   Micro-invertebrate Chornic NOEC    
#> 14 trichium       36.4 5        Paramecium   Micro-organism     Chronic IC50    
#> 15 caudatum      492   5        Paramecium   Micro-organism     Chronic IC50    
#> 16 antipodarum    20   28       Potamopyrgus Mollusc            Chronic NOEC    
#> 17 cornuarietis   50   14       Marisa       Mollusc            Chronic NOEC    
#> 18 acuta         200   21       Physa        Mollusc            Chronic LOEC    
#> 19 sp.          1600   NA       Heteromyenia Sponge             Chronic NOEC    
#> 
#> $anzg_bisphenol_a_marine
#> # A tibble: 8 × 6
#>   Species          Conc Duration Genus              Group       Toxicity_measure
#>   <chr>           <dbl> <chr>    <chr>              <chr>       <chr>           
#> 1 cordatum       302    72       Prorocentrum       Dinoflagel… Chronic EC50    
#> 2 polykrikoides 3470    72       Margalefidinium    Dinoflagel… Chronic EC50    
#> 3 pulcherrimus    45.6  920      Hemicentrotus      Echinoderm  Chronic LOEC    
#> 4 lividus         38.8  0.5      Paracentrotus      Echinoderm  Acute EC50      
#> 5 purpuratus      45.3  96       Strongylocentrotus Echinoderm  Chronic EC50    
#> 6 diversicolor     0.19 96       Haliotis           Mollusc     Chronic EC5     
#> 7 japonicus       20    96       Tigriopus          Crustacean  Acute LC50      
#> 8 bahia          103    96       Americamysis       Crustacean  Acute LC50      
#> 
#> $anzg_boron_fresh
#> # A tibble: 21 × 3
#>    Species  Conc Species_Genus        
#>    <chr>   <dbl> <chr>                
#>  1 sp. A    17   auratus_Carassius    
#>  2 sp. B     6.6 azteca_Hyalella      
#>  3 sp. C     6.1 densa_Egeria         
#>  4 sp. D     1.4 disperma_Lemna       
#>  5 sp. E     5.6 dubia_Ceriodaphnia   
#>  6 sp. F    41   fowleri_Anaxyrus     
#>  7 sp. G     2.4 magna_Daphnia        
#>  8 sp. H     4   mrigala_Cirrhinus    
#>  9 sp. I     6.2 mykiss_Oncorhynchus  
#> 10 sp. J     4.9 ochreatus_Potamogeton
#> # ℹ 11 more rows
#> 
#> $anzg_chlorine_marine
#> # A tibble: 29 × 7
#>    Species       Conc Duration    Genus       Group  Life_stage Toxicity_measure
#>    <chr>        <dbl> <chr>       <chr>       <chr>  <chr>      <chr>           
#>  1 excentricus    6.4 0.003470833 Dendraster  Echin… Sperm      Acute EC50      
#>  2 plicatilis    90   0.020833333 Brachionus  Rotif… Not stated Acute LC50      
#>  3 virginica     23   4           Crassostrea Mollu… Larva      Acute LC50      
#>  4 tonsa         29   4           Acartia     Crust… Not stated Acute LC50      
#>  5 sp.          687   4           Pontogeneia Crust… Adult      Acute LC50      
#>  6 sp.          145   4           Anonyx      Crust… Adult      Acute LC50      
#>  7 americanus  2890   0.041666667 Homarus     Crust… Larva      Acute LC50      
#>  8 sp.          162   4           Neomysis    Crust… Adult      Acute LC50      
#>  9 bahia         68   4           Mysidopsis  Crust… Juvenile   Acute LC50      
#> 10 danae        178   4           Pandalus    Crust… Juvenile … Acute LC50      
#> # ℹ 19 more rows
#> 
#> $anzg_chromium_III_fresh
#> # A tibble: 13 × 6
#>    Species        Conc Duration Genus           Group      Toxicity_measure
#>    <chr>         <dbl> <chr>    <chr>           <chr>      <chr>           
#>  1 ambiguum       19   48       Spirostomum     Protozoa   Chronic EC50    
#>  2 subcapitata     3.4 72       Raphidocelis    Microalga  Chronic EC50    
#>  3 kessleri       10   72       Chlorella       Microalga  Chronic EC50    
#>  4 chlorelloides 557   72       Dictyosphaerium Microalga  Chronic EC50    
#>  5 calyciflorus   82   24       Brachionus      Rotifer    Acute LC50      
#>  6 quadridentata 128   24       Lecane          Rotifer    Acute LC50      
#>  7 magna         330   504      Daphnia         Crustacean Chronic EC16    
#>  8 similis       324   48       Daphnia         Crustacean Acute EC50      
#>  9 mykiss         48   1,728    Oncorhynchus    Fish       Chronic NOEC    
#> 10 reticulata    333   96       Poecilia        Fish       Acute LC50      
#> 11 auratus       410   96       Carassius       Fish       Acute LC50      
#> 12 promelas      507   96       Pimephales      Fish       Acute LC50      
#> 13 macrochirus   746   96       Lepomis         Fish       Acute LC50      
#> 
#> $anzg_copper_marine
#> # A tibble: 45 × 9
#>    Species       Conc Duration Genus       Group Life_stage Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr>       <chr> <chr>      <chr>  <chr>        
#>  1 punctulata    1.4  3        Entomoneis  Diat… Exponenti… Bacil… Population g…
#>  2 polymorphus   0.2  3        Minutocell… Diat… Exponenti… Bacil… Population g…
#>  3 closterium    3.3  3        Ceratoneis  Diat… Exponenti… Bacil… Population g…
#>  4 tricornutum   1    3        Phaeodacty… Diat… Exponenti… Bacil… Population b…
#>  5 huxleyi       8.5  3        Coccolithus Gold… Exponenti… Hapto… Population g…
#>  6 oceanica      1.3  3        Gephyrocap… Gold… Exponenti… Hapto… Population g…
#>  7 sulcata       0.84 3        Proteomonas Gold… Exponenti… Hapto… Population g…
#>  8 lutea         2.7  3        Tisochrysis Gold… Exponenti… Hapto… Population g…
#>  9 sp.         300    3        Cyanobium   Cyan… Exponenti… Cyano… Population a…
#> 10 tertiolecta   8    3        Dunaliella  Gree… Exponenti… Chlor… Population g…
#> # ℹ 35 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_dioxins_fresh
#> # A tibble: 8 × 9
#>   Species        Conc Duration Genus        Group Life_stage Notes Test_endpoint
#>   <chr>         <dbl> <chr>    <chr>        <chr> <chr>      <chr> <chr>        
#> 1 carpio     0.000024 132      Cyprinus     Fish  Adult      2,3,… Mortality    
#> 2 lucius     0.0001   15       Esox         Fish  Egg        2,3,… Mortality    
#> 3 kisutch    0.00056  64       Oncorhynchus Fish  Juvenile   2,3,… Mortality    
#> 4 mykiss     0.000015 56       Oncorhynchus Fish  Fry        2,3,… Growth       
#> 5 latipes    0.0025   11       Oryzias      Fish  Embryo     2,3,… Mortality    
#> 6 promelas   0.00059  7        Pimephales   Fish  Embryo     2,3,… Mortality    
#> 7 fontinalis 0.0009   82       Salvelinus   Fish  Egg        2,3,… Mortality    
#> 8 namaycush  0.00125  92       Salvelinus   Fish  Egg        2,3,… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_diuron_fresh
#> # A tibble: 16 × 8
#>    Species                    Conc Duration Genus Group Life_stage Test_endpoint
#>    <chr>                     <dbl> <chr>    <chr> <chr> <chr>      <chr>        
#>  1 minutissimum              10.3  4        Achn… Diat… Planktoni… Growth rate  
#>  2 accomoda                 315    4        Crat… Diat… Planktoni… Growth rate  
#>  3 meneghiniana               4.9  4        Cycl… Diat… Planktoni… Growth rate  
#>  4 silesiacum                10.4  4        Ency… Diat… Planktoni… Growth rate  
#>  5 minima                  1886    4        Eoli… Diat… Planktoni… Growth rate  
#>  6 capucina var. vaucheri…    0.54 4        Frag… Diat… Planktoni… Growth rate  
#>  7 rumpens                    7.43 4        Frag… Diat… Planktoni… Growth rate  
#>  8 ulna                      17.6  4        Frag… Diat… Planktoni… Growth rate  
#>  9 parvulum                 365    4        Gomp… Diat… Planktoni… Growth rate  
#> 10 fossalis                  86.5  4        Maya… Diat… Planktoni… Growth rate  
#> 11 pelliculosa                9.17 3        Navi… Diat… Not stated Biomass yiel…
#> 12 palea                    199    4        Nitz… Diat… Planktoni… Growth rate  
#> 13 subspicatus                2.3  3        Scen… Gree… Not stated Biomass yiel…
#> 14 capricornutum              0.44 4        Sele… Gree… Not stated Biomass yiel…
#> 15 gibba                      2.49 7        Lemna Macr… Not stated Frond number…
#> 16 leopoliensis               1.14 3        Syne… Cyan… Not stated Biomass yiel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_diuron_marine
#> # A tibble: 12 × 8
#>    Species   Conc Duration Genus Group Life_stage Test_endpoint Toxicity_measure
#>    <chr>    <dbl> <chr>    <chr> <chr> <chr>      <chr>         <chr>           
#>  1 muelleri  1.5  3        Chae… Diat… Exponenti… Specific gro… Chronic NEC     
#>  2 punctul…  2    3        Ento… Diat… Not stated Cell density  Chronic NOEC    
#>  3 closter…  2    3        Nitz… Diat… Not stated Cell density  Chronic NOEC    
#>  4 pyrifor…  2.2  3        Neph… Gree… Not stated Cell density  Chronic EC10    
#>  5 sp.       1.64 3        Tetr… Gree… Exponenti… Specific gro… Chronic EC10    
#>  6 salina    1.7  3        Rhod… Cryp… Exponenti… Specific gro… Chronic NEC     
#>  7 goreaui   2.5  14       Clad… Dino… Exponenti… Specific gro… Chronic EC10    
#>  8 huxleyi   0.54 3        Emil… Gold… Exponenti… Cell density  Chronic NOEC    
#>  9 galbana   1.09 3        Isoc… Gold… Not stated Cell density  Chronic EC10    
#> 10 lutea     0.6  3        Tiso… Gold… Exponenti… Specific gro… Chronic EC10    
#> 11 japonica  2.3  15       Sacc… Brow… Thalli     Fresh weight  Chronic EC10    
#> 12 marina    2.5  10       Zost… Macr… Not stated Biomass (old… Chronic NOEC    
#> 
#> $anzg_fipronil_fresh
#> # A tibble: 13 × 10
#>    Species       Conc Duration Genus Group Life_stage Notes Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr> <chr> <chr>      <chr> <chr>  <chr>        
#>  1 brevilineata 0.015 2        Cheu… Inse… Larvae     Acut… Arthr… Mortality    
#>  2 vittatum     0.023 2        Simu… Inse… Larvae     Acut… Arthr… Mortality    
#>  3 quinquefasc… 0.035 1        Culex Inse… Larvae     Acut… Arthr… Mortality    
#>  4 crassicauda… 0.042 2        Chir… Inse… Larvae     Acut… Arthr… Mortality    
#>  5 paripes      0.042 2        Glyp… Inse… Larvae     Acut… Arthr… Mortality    
#>  6 taeniorhync… 0.043 2        Aedes Inse… Larvae     Acut… Arthr… Mortality    
#>  7 quadrimacul… 0.043 2        Anop… Inse… Larvae     Acut… Arthr… Mortality    
#>  8 sp.          0.044 4        Hexa… Inse… Nymph      Acut… Arthr… Mortality    
#>  9 nigripalpus  0.087 2        Culex Inse… Larvae     Acut… Arthr… Mortality    
#> 10 nubiferum    0.1   2        Poly… Inse… Larvae     Acut… Arthr… Mortality    
#> 11 aegypti      0.12  1        Aedes Inse… Larvae     Acut… Arthr… Mortality    
#> 12 annularius   0.245 2        Chir… Inse… Larvae     Acut… Arthr… Mortality    
#> 13 albopictus   0.81  2        Aedes Inse… Larvae     Acut… Arthr… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_fluoride_fresh
#> # A tibble: 22 × 9
#>    Species       Conc Duration Genus        Group Life_stage Notes Test_endpoint
#>    <chr>        <dbl> <chr>    <chr>        <chr> <chr>      <chr> <chr>        
#>  1 vulgaris        95 15       Chlorella    Gree… Not stated Valu… Growth       
#>  2 quadricauda     50 6.3      Scenedesmus  Gree… Not stated Valu… Growth       
#>  3 subspicata     127 3        Scenedesmus  Gree… Not stated Valu… Growth       
#>  4 subcapitata    195 3        Raphidocelis Gree… Not stated Valu… Growth       
#>  5 braunii         50 6.3      Ankistrodes… Gree… Not stated Valu… Growth       
#>  6 pyriformis      50 6.3      Nephroselmis Gree… Not stated Valu… Growth       
#>  7 meneghiniana    50 6.3      Cyclotella   Diat… Not stated Valu… Growth       
#>  8 minutus         50 6.3      Stephanodis… Diat… Not stated Valu… Growth       
#>  9 limnetica       50 6.3      Oscillatoria Cyan… Not stated Valu… Growth       
#> 10 leopoliensis    25 6.3      Synechococc… Cyan… Not stated Valu… Growth       
#> # ℹ 12 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_glyphosate_fresh
#> # A tibble: 15 × 9
#>    Species          Conc Duration Genus    Group Life_stage Phylum Test_endpoint
#>    <chr>           <dbl> <chr>    <chr>    <chr> <chr>      <chr>  <chr>        
#>  1 flosaquae       12000 5        Anabaena Blue… Not stated Cyano… Biomass yiel…
#>  2 dubia           65000 7        Cerioda… Crus… <24-hour … Arthr… Survival     
#>  3 quadricarinatus 22500 50       Cherax   Crus… Advanced … Arthr… Growth       
#>  4 saccharophila    1082 3        Chlorel… Gree… Exponenti… Chlor… Cell density 
#>  5 magna             450 21       Daphnia  Crus… Neonate    Arthr… Reproduction 
#>  6 azteca          19145 14       Hyalella Amph… Juvenile   Arthr… Survival     
#>  7 siliquoidea     12500 21       Lampsil… Biva… Juvenile   Mollu… Shell length 
#>  8 gibba            1400 14       Lemna    Macr… Not stated Trach… Frond number…
#>  9 minor            3780 7        Lemna    Macr… Not stated Trach… Chlorophyll-…
#> 10 pelliculosa      1800 5        Navicula Diat… Not stated Bacil… Biomass yiel…
#> 11 columella         316 12       Pseudos… Gast… Embryo     Mollu… Hatching suc…
#> 12 acutus           2000 4        Scenede… Gree… Not stated Chlor… Chlorophyll-…
#> 13 quadricauda       770 4        Scenede… Gree… Not stated Chlor… Chlorophyll-…
#> 14 subspicatus       400 3        Scenede… Gree… Exponenti… Chlor… Cell density 
#> 15 capricornutum   10000 5        Selenas… Gree… Not stated Chlor… Chlorophyll-…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_iron_fresh
#> # A tibble: 20 × 8
#>    Species   Conc Duration Genus Group Life_stage Test_endpoint Toxicity_measure
#>    <chr>    <dbl> <chr>    <chr> <chr> <chr>      <chr>         <chr>           
#>  1 acumina…  6900 21       Alat… Fung… NR         Growth        Chronic NOEC    
#>  2 tetracl…  6900 21       Arti… Fung… NR         Growth        Chronic NOEC    
#>  3 elegans   6900 21       Tetr… Fung… NR         Growth        Chronic NOEC    
#>  4 subcapi…   442 3        Raph… Micr… Not stated Yield         Chronic EC10    
#>  5 austral…  1000 64       Phra… Macr… Seedling   Growth        Chronic NOEC    
#>  6 dilatata   957 5        Euch… Roti… Neonate    Reproduction  Chronic LC10    
#>  7 variega…   470 35       Lumb… Anne… Worm       Reproduction  Chronic EC10    
#>  8 dorotoc… 40000 30       Duge… Plan… Not stated Growth        Chronic EC10    
#>  9 limbata   7863 30       Hexa… Inse… Nymph      Survival      Chronic EC10    
#> 10 margina… 50000 30       Lept… Inse… Larvae     Immobility    Chronic NOEC    
#> 11 dubia      383 7        Ceri… Crus… Neonate    Reproduction  Chronic EC10    
#> 12 magna     4380 21       Daph… Crus… Neonate    Reproduction  Chronic EC16    
#> 13 pulex      852 21       Daph… Crus… Neonate    Reproduction  Chronic NOEC    
#> 14 boreas    2607 35       Bufo  Amph… Tadpole    Biomass       Chronic EC10    
#> 15 kisutch   3040 7        Onco… Fish  Larvae     Mortality     Chronic NOECâ†’…
#> 16 latipes  25000 7        Oryz… Fish  Larvae     Mortality     Chronic NOEC    
#> 17 promelas   192 7        Pime… Fish  Larvae     Growth        Chronic EC10    
#> 18 william…   868 78       Pros… Fish  Egg        Biomass       Chronic EC10    
#> 19 trutta    5000 79       Salmo Fish  Egg        Biomass       Chronic EC20    
#> 20 fontina… 10280 245      Salv… Fish  3 months   Growth        Chronic NOEC    
#> 
#> $anzg_iron_marine
#> # A tibble: 16 × 8
#>    Species   Conc Duration Genus Group Life_stage Test_endpoint Toxicity_measure
#>    <chr>    <dbl> <chr>    <chr> <chr> <chr>      <chr>         <chr>           
#>  1 galbana  50000 4        Isoc… Micr… Not appli… Growth rate … Chronic NOEC    
#>  2 spathul… 18700 0.229    Acro… Cnid… Gametes    Fertilisation Chronic EC10    
#>  3 daedalea  2750 0.229    Plat… Cnid… Gametes    Fertilisation Chronic NOEC    
#>  4 tubercu…  2000 3        Heli… Echi… Embryo/la… Larval devel… Chronic NOEC    
#>  5 trapezia   935 2        Anad… Moll… Embryo     Abnormalities Chronic NEC     
#>  6 austral…   893 2        Barn… Moll… Embryo     Abnormalities Chronic NEC     
#>  7 tenuico…   806 2        Fulv… Moll… Embryo     Abnormalities Chronic NEC     
#>  8 alba       810 2        Hiat… Moll… Embryo     Abnormalities Chronic NEC     
#>  9 crenatus  1020 2        Irus  Moll… Embryo     Abnormalities Chronic NEC     
#> 10 gigas      724 2        Maga… Moll… Embryo     Abnormalities Chronic NEC     
#> 11 glomera…   738 2        Sacc… Moll… Embryo     Abnormalities Chronic NEC     
#> 12 livida    1270 2        Scae… Moll… Embryo     Abnormalities Chronic NEC     
#> 13 trigone…   948 2        Spis… Moll… Embryo     Abnormalities Chronic NEC     
#> 14 securis    896 2        Xeno… Moll… Embryo     Abnormalities Chronic NEC     
#> 15 rubra     4360 2        Hali… Moll… Embryoâ€“… Normal devel… Chronic EC10    
#> 16 anthonyi  1000 7        Canc… Crus… Embryo     Hatching      Chronic NOEC    
#> 
#> $anzg_mancozeb_fresh
#> # A tibble: 8 × 9
#>   Species        Conc Duration Genus       Group Life_stage Phylum Test_endpoint
#>   <chr>         <dbl> <chr>    <chr>       <chr> <chr>      <chr>  <chr>        
#> 1 pyrenoidosa   20    4        Chlorella   Micr… Not stated Chlor… Growth       
#> 2 vulgaris     100    4        Chlorella   Micr… Not stated Chlor… Growth       
#> 3 quadricauda  100    4        Scenedesmus Micr… Not stated Chlor… Growth       
#> 4 subcapitata  100    4        Raphidocel… Micr… Not stated Chlor… Growth       
#> 5 obliquus     500    4        Scenedesmus Micr… Not stated Chlor… Growth       
#> 6 magna          7    21       Daphnia     Crus… Neonate    Arthr… Reproduction 
#> 7 dilutus     2100    10       Chironomus  Inse… Larvae     Arthr… Survival     
#> 8 promelas       1.35 215      Pimephales  Fish  Larvae     Chord… Growth       
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_manganese_marine
#> # A tibble: 18 × 9
#>    Species        Conc Duration Genus      Group Life_stage Phylum Test_endpoint
#>    <chr>         <dbl> <chr>    <chr>      <chr> <chr>      <chr>  <chr>        
#>  1 closterium    18000 3        Ceratoneis Diat… N.A.       Bacil… Growth rate  
#>  2 lutea        125000 3        Isochrysis Gold… Log phase  Hapto… Growth rate  
#>  3 millepora      1090 14       Acropora   Cnid… Adult      Cnida… Tissue sloug…
#>  4 muricata        358 2        Acropora   Cnid… Adult      Cnida… Tissue sloug…
#>  5 spathulata      304 2        Acropora   Cnid… Adult      Cnida… Tissue sloug…
#>  6 daedalea      54000 0.229    Platygyra  Cnid… Gametes    Cnida… Fertilisation
#>  7 pistillata      374 2        Stylophora Cnid… Adult      Cnida… Tissue sloug…
#>  8 tuberculata    1580 3        Heliocida… Echi… Embryo     Echin… Embryo devel…
#>  9 trapezia       1040 2        Anadara    Moll… Embryo     Mollu… Embryo devel…
#> 10 australasiae   1780 2        Barnea     Moll… Embryo     Mollu… Embryo devel…
#> 11 tenuicostata   1460 2        Fulvia     Moll… Embryo     Mollu… Embryo devel…
#> 12 alba           1520 2        Hiatula    Moll… Embryo     Mollu… Embryo devel…
#> 13 crenatus       2410 2        Irus       Moll… Embryo     Mollu… Embryo devel…
#> 14 gigas           650 2        Magallana  Moll… Embryo     Mollu… Embryo devel…
#> 15 glomerata       654 2        Saccostrea Moll… Embryo     Mollu… Embryo devel…
#> 16 livida          959 2        Scaeochla… Moll… Embryo     Mollu… Embryo devel…
#> 17 trigonella     2090 2        Spisula    Moll… Embryo     Mollu… Embryo devel…
#> 18 securis         755 2        Xenostrob… Moll… Embryo     Mollu… Embryo devel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_mcpa_fresh
#> # A tibble: 16 × 9
#>    Species           Conc Duration Genus   Group Life_stage Phylum Test_endpoint
#>    <chr>            <dbl> <chr>    <chr>   <chr> <chr>      <chr>  <chr>        
#>  1 subcapitata       32   4        Raphid… Gree… Not stated Chlor… Growth       
#>  2 quadricauda    17020   20       Scened… Gree… Not stated Chlor… Growth       
#>  3 subspicatus   143000   3        Desmod… Gree… Not stated Chlor… Growth       
#>  4 flos-aquae       470   5        Anabae… Blue… Not stated Cyano… Growth       
#>  5 gibba             14   14       Lemna   Macr… Not stated Trach… Growth       
#>  6 minor            248   7        Lemna   Macr… Not stated Trach… Growth       
#>  7 pelliculosa        7.7 5        Navicu… Diat… Not stated Bacil… Growth       
#>  8 sp.               20   2        Gompho… Diat… Not stated Bacil… Growth       
#>  9 gracilis          20   2        Encyon… Diat… Not stated Bacil… Growth       
#> 10 ulna              20   2        Ulnaria Diat… Not stated Bacil… Growth       
#> 11 gracile          500   2        Gompho… Diat… Not stated Bacil… Growth       
#> 12 sp.              500   2        Cymbel… Diat… Not stated Bacil… Growth       
#> 13 minutissimum     500   2        Achnan… Diat… Not stated Bacil… Growth       
#> 14 cf. incisa       500   2        Eunotia Diat… Not stated Bacil… Growth       
#> 15 cryptotenella    500   2        Navicu… Diat… Not stated Bacil… Growth       
#> 16 magna          13000   21       Daphnia Crus… Neonate    Arthr… Immobilisati…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_metolachlor_fresh
#> # A tibble: 21 × 10
#>    Species       Conc Duration Genus Group Life_stage Notes Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr> <chr> <chr>      <chr> <chr>  <chr>        
#>  1 minutissimum  6528 4        Achn… Diat… Exponenti… Spec… Bacil… Cell density 
#>  2 flosaquae      240 5        Anab… Blue… Not stated NA    Cyano… Biomass yiel…
#>  3 demersum        14 14       Cera… Macr… Not stated Spec… Trach… Wet weight   
#>  4 reinhardtii    228 4        Chla… Gree… Not stated Spec… Chlor… Chlorophyll-…
#>  5 pyrenoidosa      1 4        Chlo… Gree… Exponenti… Spec… Chlor… Chlorophyll-…
#>  6 accomoda      4016 4        Crat… Diat… Exponenti… Spec… Bacil… Chlorophyll-…
#>  7 meneghiniana   925 4        Cycl… Diat… Exponenti… Spec… Bacil… Cell density 
#>  8 magna          224 21       Daph… Macr… <24 hour … NA    Arthr… Young per fe…
#>  9 canadensis     471 14       Elod… Macr… Not stated Spec… Trach… Wet weight   
#> 10 silesiacum    1048 4        Ency… Diat… Exponenti… Spec… Bacil… Chlorophyll-…
#> # ℹ 11 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_metsulfuron_methyl_fresh
#> # A tibble: 8 × 10
#>   Species        Conc Duration Genus Group Life_stage Notes Phylum Test_endpoint
#>   <chr>         <dbl> <chr>    <chr> <chr> <chr>      <chr> <chr>  <chr>        
#> 1 flos-aquae  9.54e+1 5        Anab… Blue… Not stated NA    Cyano… Biomass yiel…
#> 2 canadensis  5.4 e-2 8        Elod… Macr… Apical sh… Apic… Trach… Shoot length 
#> 3 gibba       1.93e-1 7        Lemna Macr… Not stated NA    Trach… Frond count  
#> 4 minor       1   e-1 42       Lemna Macr… Exponenti… NA    Trach… Frond count  
#> 5 spicatum    4   e-1 14       Myri… Macr… Apical sh… NA    Trach… Root occurre…
#> 6 pelliculosa 9.28e+4 4        Navi… Diat… Not stated NA    Bacil… Biomass yiel…
#> 7 mykiss      4.5 e+3 90       Onco… Fish  Early life NA    Chord… Mortality    
#> 8 subcapitata 1   e+1 5        Pseu… Gree… Not stated NA    Chlor… Biomass yiel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nickel_marine
#> # A tibble: 31 × 9
#>    Species        Conc Duration Genus      Group Life_stage Phylum Test_endpoint
#>    <chr>         <dbl> <chr>    <chr>      <chr> <chr>      <chr>  <chr>        
#>  1 sp.          3700   3        Cyanobium  Cyan… 6 x 10^3 … Cyano… Growth rate  
#>  2 closterium   2870   3        Ceratoneis Diat… 5-6 d old… Bacil… Growth rate  
#>  3 costatum      132   4        Skeletone… Diat… Not stated Bacil… Growth       
#>  4 tertiolecta 17900   4        Dunaliella Gree… Not stated Chlor… Growth       
#>  5 lutea         250   3        Isochrysis Brow… 5-6 d old… Hapto… Growth rate  
#>  6 sp.           310   3        Symbiodin… Dino… 6-7 d old… Dinop… Growth rate  
#>  7 parvula       144   10       Champia    Red … Adult      Rhodo… Reproduction 
#>  8 pyrifera       96.7 10       Macrocyst… Brow… Zoospore   Phaeo… Reproduction 
#>  9 sinjiensis      5.5 3.33     Acartia    Crus… Egg        Arthr… Development  
#> 10 amphitrite     67   4        Amphibala… Crus… Nauplius   Arthr… Metamorphosis
#> # ℹ 21 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nitrate_hard_fresh
#> # A tibble: 12 × 9
#>    Species             Conc Duration Genus Group Life_stage Phylum Test_endpoint
#>    <chr>              <dbl> <chr>    <chr> <chr> <chr>      <chr>  <chr>        
#>  1 sp.               1600   3        Chlo… Micr… Exponenti… Chlor… Growth       
#>  2 solitaria         1700   3        Oocy… Micr… Exponenti… Chlor… Growth       
#>  3 viridissima        220   4        Hydra Cnid… Adult      Cnida… Population g…
#>  4 dilutus            120   10       Chir… Inse… Larvae     Arthr… Growth weight
#>  5 dubia               28.5 7        Ceri… Crus… Neonates   Arthr… Reproduction 
#>  6 magna              358   7        Daph… Crus… Neonates   Arthr… Reproduction 
#>  7 azteca             102   14       Hyal… Crus… Juvenile   Arthr… Growth weight
#>  8 heilongjiangensis   45   13       Simo… Crus… Neonates   Arthr… Reproduction 
#>  9 topeka             268   30       Notr… Fish  Juvenile   Chord… Growth       
#> 10 mykiss             335   42       Onco… Fish  Fry        Chord… Growth       
#> 11 promelas            46.7 32       Pime… Fish  Embryo la… Chord… Growth weight
#> 12 versicolor          47   52       Hyla  Amph… Juvenile   Chord… Metamorphosis
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nitrate_moderate_fresh
#> # A tibble: 11 × 9
#>    Species      Conc Duration Genus        Group Life_stage Phylum Test_endpoint
#>    <chr>       <dbl> <chr>    <chr>        <chr> <chr>      <chr>  <chr>        
#>  1 siliquoidea  17   28       Lampsilis    Moll… Juvenile   Mollu… Weight       
#>  2 dilutus       5.8 10       Chironomus   Inse… Larva      Arthr… Growth weight
#>  3 sp.          20.3 20       Deleatidium  Inse… Larva      Arthr… Mortality    
#>  4 dubia        19.4 7        Ceriodaphnia Crus… Neonates   Arthr… Reproduction 
#>  5 azteca       11   42       Hyalella     Crus… Juvenile   Arthr… Growth weight
#>  6 rerio       200   29       Danio        Fish  Juvenile   Chord… Mortality an…
#>  7 maculatus    26.6 40       Galaxias     Fish  Juvenile   Chord… Mortality    
#>  8 cotidianus   24.9 21       Gobiomorphus Fish  Juvenile   Chord… Mortality    
#>  9 mykiss      120   42       Oncorhynchus Fish  Fry        Chord… Yolk develop…
#> 10 promelas      6.6 7        Pimephales   Fish  Embryo la… Chord… Growth weight
#> 11 regilla      56.7 10       Pseudacris   Amph… Embryo     Chord… Length       
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nitrate_soft_fresh
#> # A tibble: 14 × 9
#>    Species         Conc Duration Genus     Group Life_stage Phylum Test_endpoint
#>    <chr>          <dbl> <chr>    <chr>     <chr> <chr>      <chr>  <chr>        
#>  1 subcapitata    247   3        Raphidoc… Micr… Exponenti… Chlor… Growth       
#>  2 novaezelandiae   8.6 60       Sphaerium Moll… Juvenile   Mollu… Mortality    
#>  3 antipodarum      1.4 40       Potamopy… Moll… Juvenile   Mollu… Growth length
#>  4 planifrons       2.2 60       Paraneph… Crus… Juvenile   Arthr… Growth length
#>  5 clupeaformis     6.3 126      Coregonus Fish  Embryo al… Chord… Development  
#>  6 maculatus        2   40       Galaxias  Fish  Juvenile   Chord… Mortality    
#>  7 cotidianus      22.5 21       Gobiomor… Fish  Juvenile   Chord… Growth weight
#>  8 mykiss           2.2 30       Oncorhyn… Fish  Fry        Chord… Mortality    
#>  9 tshawytscha      2.3 30       Oncorhyn… Fish  Fry        Chord… Mortality    
#> 10 promelas        52   7        Pimephal… Fish  Embryo la… Chord… Growth weight
#> 11 clarkii          4.5 30       Salmo     Fish  Fry        Chord… Mortality    
#> 12 namaycush        1.6 146      Salvelin… Fish  Embryo al… Chord… Growth weight
#> 13 aurora         117   16       Rana      Amph… Embryo la… Chord… Growth weight
#> 14 laevis          24.8 10       Xenopus   Amph… Tadpole    Chord… Growth weight
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_paraquat_fresh
#> # A tibble: 10 × 9
#>    Species       Conc Duration Genus       Group Life_stage Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr>       <chr> <chr>      <chr>  <chr>        
#>  1 cf. chalybea   2.6 4        Oscillator… Cyan… Not stated Cyano… Growth       
#>  2 subcapitata  114   4        Raphidocel… Gree… Not stated Chlor… Growth       
#>  3 minor          5.1 4        Lemna       Macr… Not stated Trach… Growth       
#>  4 gibba          1   28       Lemna       Macr… Not stated Trach… Growth       
#>  5 paucicostata  31.8 7        Lemna       Macr… Not stated Trach… Growth       
#>  6 sp.           15.2 2        Mesocyclops Crus… Nauplii    Arthr… Mortality    
#>  7 aspericornis  20.7 2        Mesocyclops Crus… Nauplii    Arthr… Mortality    
#>  8 magna        125   2        Daphnia     Crus… Neonates   Arthr… Immobilisati…
#>  9 mykiss         8.4 1        Oncorhynch… Fish  Juveniles  Chord… Mortality    
#> 10 laevis        13.8 5        Xenopus     Amph… Embryo     Chord… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_perfluorooctane_sulfonate_pfos_fresh
#> # A tibble: 37 × 9
#>    Species             Conc Duration Genus Group Life_stage Phylum Test_endpoint
#>    <chr>              <dbl> <chr>    <chr> <chr> <chr>      <chr>  <chr>        
#>  1 gargarizans       2000   30       Bufo  Amph… Tadpole    Chord… Mortality    
#>  2 catesbeiana         57.6 72       Lith… Amph… Tadpole    Chord… Growth       
#>  3 pipiens             10   40       Lith… Amph… Tadpole    Chord… Development  
#>  4 laevis            1250   36       Xeno… Amph… Tadpole    Chord… Growth       
#>  5 tropicalis         590   150      Xeno… Amph… Embryo     Chord… Growth       
#>  6 flos-aquae       82000   4        Anab… Cyan… Not stated Cyano… Growth and b…
#>  7 dubia             6900   6        Ceri… Crus… Neonate    Arthr… Reproduction 
#>  8 diaptomus          400   28       Cycl… Crus… Not stated Arthr… Survival     
#>  9 canthocamptus s…  1000   35       Cycl… Crus… Not stated Arthr… Survival     
#> 10 carinata             0.4 21       Daph… Crus… Neonate    Arthr… Reproduction 
#> # ℹ 27 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_picloram_fresh
#> # A tibble: 12 × 9
#>    Species         Conc Duration Genus     Group Life_stage Phylum Test_endpoint
#>    <chr>          <dbl> <chr>    <chr>     <chr> <chr>      <chr>  <chr>        
#>  1 subcapitata     8944 4        Raphidoc… Micr… Not stated Chlor… Growth       
#>  2 vulgaris       10000 4        Chlorella Micr… Not stated Chlor… Growth       
#>  3 pseudolimnaeus  1650 4        Gammarus  Crus… Juvenile   Arthr… Mortality    
#>  4 fasciculatus    2700 4        Gammarus  Crus… Adult      Arthr… Mortality    
#>  5 magna          11800 21       Daphnia   Crus… Neonate    Arthr… Reproduction 
#>  6 californica     4800 10       Pteronar… Inse… YC-2       Arthr… Mortality    
#>  7 punctatus        140 4        Ictalurus Fish  Juvenile   Chord… Mortality    
#>  8 clarkii          229 4        Oncorhyn… Fish  Juvenile   Chord… Mortality    
#>  9 namaycush        236 4        Salvelin… Fish  Juvenile   Chord… Mortality    
#> 10 mykiss           550 60       Oncorhyn… Fish  Embryo     Chord… Growth       
#> 11 macrochirus     2226 4        Lepomis   Fish  Juvenile   Chord… Mortality    
#> 12 promelas        5530 4        Pimephal… Fish  Juvenile   Chord… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_simazine_fresh
#> # A tibble: 20 × 9
#>    Species       Conc Duration Genus       Group Life_stage Phylum Test_endpoint
#>    <chr>        <dbl> <chr>    <chr>       <chr> <chr>      <chr>  <chr>        
#>  1 magna       1000   21       Daphnia     Arth… Not stated Arthr… Mortality    
#>  2 pelliculosa   18   5        Navicula    Diat… Not stated Bacil… Cell density 
#>  3 geitleri     171   3        Chlamydomo… Gree… Exponenti… Chlor… Growth rate  
#>  4 pyrenoidosa   65   6        Chlorella   Gree… Not stated Chlor… Abundance    
#>  5 vulgaris     435   4        Chlorella   Gree… Not stated Chlor… Abundance    
#>  6 subcapitata   32   3        Pseudokirc… Gree… Not stated Chlor… Growth rate  
#>  7 obliquus      51.4 4        Scenedesmus Gree… Not stated Chlor… Growth rate  
#>  8 quadricauda   30   4        Scenedesmus Gree… Not stated Chlor… Abundance    
#>  9 auratus     1000   365      Carassius   Fish  Not stated Chord… Mortality    
#> 10 carpio        45   90       Cyprinus    Fish  Not stated Chord… Weight and m…
#> 11 macrochirus 1000   365      Lepomis     Fish  Not stated Chord… Mortality    
#> 12 mykiss       500   28       Oncorhynch… Fish  Not stated Chord… Mortality    
#> 13 promelas    1000   120      Pimephales  Fish  Early lif… Chord… Mortality    
#> 14 flos-aquae     7.2 5        Anabaena    Cyan… Not stated Cyano… Cell density 
#> 15 gramineus    100   7        Acorus      Macr… Not stated Trach… Fresh weight 
#> 16 gibba         28   14       Lemna       Macr… Not stated Trach… Biomass yield
#> 17 aquaticum     20   7        Myriophyll… Macr… 2 weeks o… Trach… Fresh weight 
#> 18 cordata      100   7        Pontederia  Macr… Not stated Trach… Fresh weight 
#> 19 latifolia    300   7        Typha       Macr… Not stated Trach… Fresh weight 
#> 20 americana     58   13       Vallisneria Macr… Not stated Trach… Length       
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_simazine_marine
#> # A tibble: 14 × 9
#>    Species         Conc Duration Genus     Group Life_stage Phylum Test_endpoint
#>    <chr>          <dbl> <chr>    <chr>     <chr> <chr>      <chr>  <chr>        
#>  1 closterium     310   3        Ceratone… Diat… Exponenti… Bacil… Growth rate  
#>  2 sp.            400   10       Chloroco… Gree… Not stated Chlor… Cell density 
#>  3 virginica     1000   7        Crassost… Biva… Spat       Mollu… Mortality an…
#>  4 goreaui        257   14       Cladocop… Dino… Exponenti… Dinof… Growth rate  
#>  5 tertiolecta   1000   10       Dunaliel… Gree… Not stated Chlor… Cell density 
#>  6 galbana        100   10       Isochrys… Gold… Not stated Hapto… Cell density 
#>  7 texana      100000   4        Neopanope Crus… Not stated Arthr… Mortality    
#>  8 kadiakensis  10000   2        Palaemon… Crus… Not stated Arthr… Mortality    
#>  9 duorarum     11300   4        Penaeus   Crus… Not stated Arthr… Mortality    
#> 10 tricornutum    100   3        Phaeodac… Diat… Exponenti… Bacil… Growth rate  
#> 11 salina          38.4 3        Rhodomon… Cryp… Exponenti… Crypt… Growth rate  
#> 12 costatum       250   5        Skeleton… Diat… Not stated Bacil… Cell density 
#> 13 sp.             37.5 3        Tetrasel… Gree… Exponenti… Chlor… Growth rate  
#> 14 lutea           60.2 3        Tisochry… Gold… Exponenti… Hapto… Growth rate  
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_sulfometuron_methyl_fresh
#> # A tibble: 6 × 9
#>   Species         Conc Duration Genus      Group Life_stage Phylum Test_endpoint
#>   <chr>          <dbl> <chr>    <chr>      <chr> <chr>      <chr>  <chr>        
#> 1 subcapitata    0.63  5        Raphidoce… Gree… Not stated Chlor… Growth       
#> 2 flos-aquae    14     5        Anabaena   Cyan… Not stated Cyano… Growth       
#> 3 pelliculosa  370     5        Navicula   Diat… Not stated Bacil… Growth       
#> 4 gibba          0.207 14       Lemna      Macr… Not stated Trach… Growth       
#> 5 magna       6100     21       Daphnia    Crus… Neonates   Arthr… Reproduction 
#> 6 laevis      1000     30       Xenopus    Amph… Embryos    Chord… Development  
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_zinc_marine
#> # A tibble: 16 × 9
#>    Species            Conc Duration Genus  Group Life_stage Phylum Test_endpoint
#>    <chr>             <dbl> <chr>    <chr>  <chr> <chr>      <chr>  <chr>        
#>  1 punctulata          153 2        Entom… Diat… Log phase  Ochro… Population g…
#>  2 closterium           84 3        Cerat… Diat… Log phase  Ochro… Population g…
#>  3 tertiolecta          54 3        Dunal… Gree… NR         Chlor… Mortality    
#>  4 fasiata             143 4        Ulva   Gree… Zoospores  Chlor… Growth and g…
#>  5 pyrifera           1070 16       Macro… Brow… Zoospores  Ochro… Reproduction 
#>  6 elegans              24 4        Hydro… Anne… Larvae     Annel… Development  
#>  7 pulchella             9 28       Aipta… Anem… Adult      Cnida… Reproduction 
#>  8 compressa            62 28       Allor… Crus… Juveniles  Arthr… Mortality    
#>  9 australiensis       230 14       Calli… Crus… Adult      Arthr… Immobilisati…
#> 10 gigas                24 2        Crass… Moll… Embryos    Mollu… Development  
#> 11 diversicolor         64 28       Halio… Moll… NR         Mollu… Growth       
#> 12 asperrima             5 2        Mimac… Moll… Larvae     Mollu… Development  
#> 13 edulis               35 2        Mytil… Moll… Eggs/Larv… Mollu… Development  
#> 14 galloprovincialis    36 2        Mytil… Moll… Embryos    Mollu… Development  
#> 15 trossulus            64 2        Mytil… Moll… Embryos    Mollu… Development  
#> 16 glomerata          2080 14       Sacco… Moll… Larvae     Mollu… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $ccme_boron
#> # A tibble: 28 × 6
#>    Species                  Conc Chemical Group        Units Medium    
#>    <chr>                   <dbl> <chr>    <fct>        <chr> <chr>     
#>  1 Oncorhynchus mykiss       2.1 Boron    Fish         mg/L  Freshwater
#>  2 Ictalurus punctatus       2.4 Boron    Fish         mg/L  Freshwater
#>  3 Micropterus salmoides     4.1 Boron    Fish         mg/L  Freshwater
#>  4 Brachydanio rerio        10   Boron    Fish         mg/L  Freshwater
#>  5 Carassius auratus        15.6 Boron    Fish         mg/L  Freshwater
#>  6 Pimephales promelas      18.3 Boron    Fish         mg/L  Freshwater
#>  7 Daphnia magna             6   Boron    Invertebrate mg/L  Freshwater
#>  8 Opercularia bimarginata  10   Boron    Invertebrate mg/L  Freshwater
#>  9 Ceriodaphnia dubia       13.4 Boron    Invertebrate mg/L  Freshwater
#> 10 Entosiphon sulcatum      15   Boron    Invertebrate mg/L  Freshwater
#> # ℹ 18 more rows
#> 
#> $ccme_cadmium
#> # A tibble: 36 × 6
#>    Species                   Conc Chemical Group Units Medium    
#>    <chr>                    <dbl> <chr>    <fct> <chr> <chr>     
#>  1 Oncorhynchus mykiss       0.23 Cadmium  Fish  ug/L  Freshwater
#>  2 Salvelinus confluentus    0.83 Cadmium  Fish  ug/L  Freshwater
#>  3 Cottus bairdi             0.96 Cadmium  Fish  ug/L  Freshwater
#>  4 Salmo salar               0.99 Cadmium  Fish  ug/L  Freshwater
#>  5 Acipenser transmontanus   1.14 Cadmium  Fish  ug/L  Freshwater
#>  6 Prosopium williamsoni     1.25 Cadmium  Fish  ug/L  Freshwater
#>  7 Salmo trutta              1.36 Cadmium  Fish  ug/L  Freshwater
#>  8 Salvelinus fontinalis     2.23 Cadmium  Fish  ug/L  Freshwater
#>  9 Oncorhynchus tshawytscha  2.29 Cadmium  Fish  ug/L  Freshwater
#> 10 Pimephales promelas       2.36 Cadmium  Fish  ug/L  Freshwater
#> # ℹ 26 more rows
#> 
#> $ccme_chloride
#> # A tibble: 28 × 6
#>    Species                       Conc Chemical Group        Units Medium    
#>    <chr>                        <dbl> <chr>    <fct>        <chr> <chr>     
#>  1 Pimephales promelas            598 Chloride Fish         mg/L  Freshwater
#>  2 Salmo trutta fario             607 Chloride Fish         mg/L  Freshwater
#>  3 Oncorhynchus mykiss            989 Chloride Fish         mg/L  Freshwater
#>  4 Xenopus laevis                1307 Chloride Amphibian    mg/L  Freshwater
#>  5 Rana pipiens                  3431 Chloride Amphibian    mg/L  Freshwater
#>  6 Lampsilis fasciola              24 Chloride Invertebrate mg/L  Freshwater
#>  7 Epioblasma torulosa rangiana    42 Chloride Invertebrate mg/L  Freshwater
#>  8 Musculium securis              121 Chloride Invertebrate mg/L  Freshwater
#>  9 Daphnia ambigua                259 Chloride Invertebrate mg/L  Freshwater
#> 10 Daphnia pulex                  368 Chloride Invertebrate mg/L  Freshwater
#> # ℹ 18 more rows
#> 
#> $ccme_endosulfan
#> # A tibble: 12 × 6
#>    Species                            Conc Chemical   Group        Units Medium 
#>    <chr>                             <dbl> <chr>      <fct>        <chr> <chr>  
#>  1 Oncorhynchus mykiss                0.05 Endosulfan Fish         ng/L  Freshw…
#>  2 Channa punctata                    0.24 Endosulfan Fish         ng/L  Freshw…
#>  3 Pimephales promelas                0.28 Endosulfan Fish         ng/L  Freshw…
#>  4 Hydra vulgaris                     0.06 Endosulfan Invertebrate ng/L  Freshw…
#>  5 Hydra viridissima                  0.07 Endosulfan Invertebrate ng/L  Freshw…
#>  6 Daphnia magna                     14.1  Endosulfan Invertebrate ng/L  Freshw…
#>  7 Ceriodaphnia dubia                14.1  Endosulfan Invertebrate ng/L  Freshw…
#>  8 Moinodaphnia macleayi             28.3  Endosulfan Invertebrate ng/L  Freshw…
#>  9 Daphnia cephalata                113.   Endosulfan Invertebrate ng/L  Freshw…
#> 10 Brachionus calyciflorus         1000    Endosulfan Invertebrate ng/L  Freshw…
#> 11 Pseudokirchneriella subcapitata  428.   Endosulfan Plant        ng/L  Freshw…
#> 12 Scenedesmus subspicatus          560    Endosulfan Plant        ng/L  Freshw…
#> 
#> $ccme_glyphosate
#> # A tibble: 18 × 6
#>    Species                           Conc Chemical   Group        Units Medium  
#>    <chr>                            <dbl> <chr>      <fct>        <chr> <chr>   
#>  1 Oncorhynchus kisutch            130000 Glyphosate Fish         ug/L  Freshwa…
#>  2 Oncorhynchus mykiss             150000 Glyphosate Fish         ug/L  Freshwa…
#>  3 Pimephales promelas              25700 Glyphosate Fish         ug/L  Freshwa…
#>  4 Ceriodaphnia dubia               65000 Glyphosate Invertebrate ug/L  Freshwa…
#>  5 Daphnia magna                    10487 Glyphosate Invertebrate ug/L  Freshwa…
#>  6 Hyalella azteca                  20500 Glyphosate Invertebrate ug/L  Freshwa…
#>  7 Pseudosuccinea columella          3162 Glyphosate Invertebrate ug/L  Freshwa…
#>  8 Anabaena flosaquae               12000 Glyphosate Plant        ug/L  Freshwa…
#>  9 Chlorella pyrenoidosa             3530 Glyphosate Plant        ug/L  Freshwa…
#> 10 Chlorella vulgaris                4696 Glyphosate Plant        ug/L  Freshwa…
#> 11 Lemna gibba                       1587 Glyphosate Plant        ug/L  Freshwa…
#> 12 Myriophyllum sibiricum            1474 Glyphosate Plant        ug/L  Freshwa…
#> 13 Navicula pelliculosa              1800 Glyphosate Plant        ug/L  Freshwa…
#> 14 Potamogeton pectinatus            3162 Glyphosate Plant        ug/L  Freshwa…
#> 15 Pseudokirchneriella subcapitata  10000 Glyphosate Plant        ug/L  Freshwa…
#> 16 Scenedesmus acutus                2820 Glyphosate Plant        ug/L  Freshwa…
#> 17 Scenedesmus obliquus             55858 Glyphosate Plant        ug/L  Freshwa…
#> 18 Scenedesmus quadricauda           1090 Glyphosate Plant        ug/L  Freshwa…
#> 
#> $ccme_silver
#> # A tibble: 9 × 6
#>   Species                Conc Chemical Group        Units Medium    
#>   <chr>                 <dbl> <chr>    <fct>        <chr> <chr>     
#> 1 Oncorhynchus mykiss    0.24 Silver   Fish         ug/L  Freshwater
#> 2 Lemna gibba            0.63 Silver   Plant        ug/L  Freshwater
#> 3 Ceriodaphnia dubia     0.78 Silver   Invertebrate ug/L  Freshwater
#> 4 Pimephales promelas    0.83 Silver   Fish         ug/L  Freshwater
#> 5 Ictalurus punctatus    1.9  Silver   Fish         ug/L  Freshwater
#> 6 Daphnia magna          2.12 Silver   Invertebrate ug/L  Freshwater
#> 7 Hyalella azteca        4    Silver   Invertebrate ug/L  Freshwater
#> 8 Chironomus tentans    13    Silver   Invertebrate ug/L  Freshwater
#> 9 Micropterus salmoides 23    Silver   Fish         ug/L  Freshwater
#> 
#> $ccme_uranium
#> # A tibble: 13 × 6
#>    Species                          Conc Chemical Group        Units Medium    
#>    <chr>                           <dbl> <chr>    <fct>        <chr> <chr>     
#>  1 Oncorhynchus mykiss               350 Uranium  Fish         ug/L  Freshwater
#>  2 Pimephales promelas              1040 Uranium  Fish         ug/L  Freshwater
#>  3 Esox lucius                      2550 Uranium  Fish         ug/L  Freshwater
#>  4 Salvelinus namaycush            13400 Uranium  Fish         ug/L  Freshwater
#>  5 Catostomus commersoni           14300 Uranium  Fish         ug/L  Freshwater
#>  6 Hyalella azteca                    12 Uranium  Invertebrate ug/L  Freshwater
#>  7 Ceriodaphnia dubia                 73 Uranium  Invertebrate ug/L  Freshwater
#>  8 Simocephalus serrulatus           480 Uranium  Invertebrate ug/L  Freshwater
#>  9 Daphnia magna                     530 Uranium  Invertebrate ug/L  Freshwater
#> 10 Chironomus tentans                930 Uranium  Invertebrate ug/L  Freshwater
#> 11 Pseudokirchneriella subcapitata    40 Uranium  Plant        ug/L  Freshwater
#> 12 Lemna minor                      3100 Uranium  Plant        ug/L  Freshwater
#> 13 Cryptomonas erosa                 172 Uranium  Plant        ug/L  Freshwater
#> 
```

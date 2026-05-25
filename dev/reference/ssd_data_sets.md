# Species Sensitivity Data Sets

Extracts the data sets for all individually documented chemicals in
ssddata.

## Usage

``` r
ssd_data_sets()
```

## Value

A named list of the available data sets for individual chemicals.

## Details

Note only datasets for chemicals that are individually documented are
returned. This does not include chemicals from the wqbench US EPA Ecotox
database. Data from wqbench can be retrieved using data("wqbench_data").
This does not include the envirotox datasets which span multiple
chemicals. Data from envirotox can be retrieved using
data("envirotox_data").

## Examples

``` r
ssd_data_sets()
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
#> # A tibble: 18 × 2
#>    Chemical   Conc
#>    <chr>     <dbl>
#>  1 a         500  
#>  2 a        1800  
#>  3 a         120  
#>  4 a         490  
#>  5 a           4  
#>  6 a          16  
#>  7 a        6250  
#>  8 a         100  
#>  9 a        7800  
#> 10 a        7990  
#> 11 a        1360  
#> 12 a        4000  
#> 13 a        1800  
#> 14 a          36.4
#> 15 a         492  
#> 16 a          50  
#> 17 a         200  
#> 18 a        1600  
#> 
#> $anon_b
#> # A tibble: 10 × 2
#>    Chemical  Conc
#>    <chr>    <dbl>
#>  1 b          1  
#>  2 b          2.6
#>  3 b          5.1
#>  4 b          8.4
#>  5 b         13.8
#>  6 b         15.2
#>  7 b         20.7
#>  8 b         31.8
#>  9 b        114  
#> 10 b        125  
#> 
#> $anon_c
#> # A tibble: 16 × 2
#>    Chemical     Conc
#>    <chr>       <dbl>
#>  1 c            32  
#>  2 c         17020  
#>  3 c        143000  
#>  4 c           470  
#>  5 c            14  
#>  6 c           248  
#>  7 c             7.7
#>  8 c            20  
#>  9 c            20  
#> 10 c            20  
#> 11 c           500  
#> 12 c           500  
#> 13 c           500  
#> 14 c           500  
#> 15 c           500  
#> 16 c         13000  
#> 
#> $anon_d
#> # A tibble: 12 × 2
#>    Chemical  Conc
#>    <chr>    <dbl>
#>  1 d         8944
#>  2 d        10000
#>  3 d         1650
#>  4 d         2700
#>  5 d        11800
#>  6 d         4800
#>  7 d          140
#>  8 d          229
#>  9 d          236
#> 10 d          550
#> 11 d         2226
#> 12 d         5530
#> 
#> $anon_e
#> # A tibble: 17 × 2
#>    Chemical    Conc
#>    <chr>      <dbl>
#>  1 e           11.2
#>  2 e           17  
#>  3 e            3.4
#>  4 e            5.5
#>  5 e           20  
#>  6 e         1376  
#>  7 e            0.8
#>  8 e         8200  
#>  9 e         3000  
#> 10 e        29050  
#> 11 e        11290  
#> 12 e         7116  
#> 13 e        13000  
#> 14 e        16400  
#> 15 e        16280  
#> 16 e         7100  
#> 17 e          100  
#> 
#> $anzg_alpha_cypermethrin_fresh
#> # A tibble: 14 × 7
#>      Conc Duration Genus             Group   Life_stage Species Toxicity_measure
#>     <dbl> <chr>    <chr>             <chr>   <chr>      <chr>   <chr>           
#>  1 27.2   96       Anabaena          Cyanob… Not stated flosaq… Chronic NOEC    
#>  2 72     96       Navicula          Diatom  Not stated pellic… Chronic NOEC    
#>  3  1.39  168      Lemna             Macrop… Not stated gibba   Chronic NOEC    
#>  4  0.002 96       Paratya           Crusta… Adults     austra… Acute LC50      
#>  5  0.025 192      Ceriodaphnia      Crusta… Neonates   dubia   Chronic NOEC    
#>  6  0.037 504      Daphnia           Crusta… Neonates   magna   Chronic NOEC    
#>  7  0.143 24       Culex             Insect  Larvae     tritae… Acute LC50      
#>  8  6     24       Anopheles         Insect  Larvae     sinens… Acute LC50      
#>  9  0.69  96       Xenopus           Amphib… Larvae     laevis  Acute LC50      
#> 10  0.063 96       Rutilus           Fish    Juveniles  rutilu… Acute LC50      
#> 11  0.092 96       Hypophthalmicthys Fish    Juveniles  molitr… Acute LC50      
#> 12  0.095 96       Huso              Fish    Juveniles  huso    Acute LC50      
#> 13  0.342 96       Oreochromis       Fish    Larvae     niloti… Acute LC50      
#> 14  0.943 96       Poecilia          Fish    Adults     reticu… Acute LC50      
#> 
#> $anzg_aluminium_marine
#> # A tibble: 18 × 6
#>     Conc Duration Genus         Group      Species            Toxicity_measure
#>    <dbl> <chr>    <chr>         <chr>      <chr>              <chr>           
#>  1    27 72       Ceratoneis    Diatom     closterium         Chronic IC10    
#>  2   610 72       Minutocellus  Diatom     polymorphus        Chronic IC10    
#>  3  2100 72       Phaeodactylum Diatom     tricornutum        Chronic IC10    
#>  4  3200 72       Tetraselmis   Microalga  sp.                Chronic IC10    
#>  5  1400 72       Dunaliella    Microalga  tertiolecta        Chronic IC10    
#>  6  9800 72       Hormosira     Brown alga banksii            Chronic NOEC    
#>  7  6800 72       Ecklonia      Brown alga radiata            Chronic IC10    
#>  8 28000 72       Heliocidaris  Echinoderm tuberculata        Chronic NOEC    
#>  9    32 72       Paracentrotus Echinoderm lividus            Chronic NOEC    
#> 10   250 72       Mytilus       Mollusc    edulis plannulatus Chronic EC10    
#> 11   410 72       Saccostrea    Mollusc    echinata           Chronic EC10    
#> 12   100 72       Saccostrea    Mollusc    glomerata          Chronic NOEC    
#> 13   640 72       Tisochrysis   Microalga  lutea              Chronic IC10    
#> 14  1300 18       Acropora      Cnidarian  tenuis             Chronic EC10    
#> 15   817 336      Exaiptasia    Cnidarian  diaphana           Chronic EC10    
#> 16   115 96       Nassarius     Mollusc    dorsatus           Chronic EC10    
#> 17   416 96       Amphibalanus  Crustacean amphitrite         Chronic EC10    
#> 18   312 72       Coenobita     Crustacean variabilis         Chronic EC10    
#> 
#> $anzg_ametryn_fresh
#> # A tibble: 8 × 6
#>      Conc Duration Genus        Group      Species       Toxicity_measure
#>     <dbl> <chr>    <chr>        <chr>      <chr>         <chr>           
#> 1    0.06 96       Chlorella    Green alga pyrenoidosa   Chronic EC50    
#> 2 2000    240      Chlorococcum Green alga sp.           Chronic EC50    
#> 3    7.2  72       Neochloris   Green alga sp.           Chronic EC50    
#> 4    4.8  72       Platymonas   Green alga sp.           Chronic EC50    
#> 5   30    96       Scenedesmus  Green alga quadricauda   Chronic EC50    
#> 6    1.14 168      Selenastrum  Green alga capricornutum Chronic NOEL    
#> 7    2    168      Lemna        Macrophyte gibba         Chronic NOEL    
#> 8    5.2  72       Stauroneis   Diatom     amphoroides   Chronic EC50    
#> 
#> $anzg_ammonia_fresh
#> # A tibble: 40 × 6
#>     Conc Duration Genus        Group      Species              Toxicity_measure
#>    <dbl> <chr>    <chr>        <chr>      <chr>                <chr>           
#>  1 165   3        Chlorella    Microalga  vulgaris             Chronic EC10    
#>  2 560   3        Raphidocelis Microalga  subcapitata          Chronic EC10    
#>  3   1.2 30       Polycelis    Flatworm   felina               Chronic NOEC    
#>  4  42   7        Ceriodaphnia Cladoceran dubia                Chronic NOEC    
#>  5  21   21       Daphnia      Cladoceran magna                Chronic NOEC    
#>  6  29   21       Chironomus   Insect     riparius             Chronic NOEC    
#>  7   7.2 29       Coloburiscus Insect     humeralis            Chronic NOEC    
#>  8   3.2 29       Deleatidium  Insect     sp.                  Chronic NOEC    
#>  9   8.9 70       Hyalella     Amphipod   azteca               Chronic NOEC    
#> 10  19   21       Neocardidina Shrimp     denticulata sinensis Chronic NOEC    
#> # ℹ 30 more rows
#> 
#> $anzg_bisphenol_a_fresh
#> # A tibble: 19 × 6
#>      Conc Duration Genus        Group              Species      Toxicity_measure
#>     <dbl> <chr>    <chr>        <chr>              <chr>        <chr>           
#>  1  500   90       Xenopus      Amphibian          laevis       Chronic NOEC    
#>  2 1800   14       Rhinella     Amphibian          arenarum     Chronic NOEC    
#>  3  120   21       Daphnia      Crustacean         magna        Chronic LC50    
#>  4  490   42       Hyalella     Crustacean         azteca       Chronic NOEC    
#>  5    4   90       Danio        Fish               rerio        Chronic LOEC    
#>  6   16   164      Pimephales   Fish               promelas     Chronic NOEC    
#>  7   60   44       Oryzias      Fish               latipes      Chronic NOEC    
#>  8  100   20       Chironomus   Insect             riparius     Chronic NOEC    
#>  9 7800   7        Lemna        Macrophyte         gibba        Chronic NOEC    
#> 10 7990   28       Bruguiera    Macrophyte         gymnorhiza   Chronic LC50    
#> 11 1360   4        Raphidocelis Microalga          subcapitata  Chronic EC10    
#> 12 4000   4        Chlorolobion Microalga          braunii      Chronic NOEC    
#> 13 1800   2        Brachionus   Micro-invertebrate calyciflorus Chornic NOEC    
#> 14   36.4 5        Paramecium   Micro-organism     trichium     Chronic IC50    
#> 15  492   5        Paramecium   Micro-organism     caudatum     Chronic IC50    
#> 16   20   28       Potamopyrgus Mollusc            antipodarum  Chronic NOEC    
#> 17   50   14       Marisa       Mollusc            cornuarietis Chronic NOEC    
#> 18  200   21       Physa        Mollusc            acuta        Chronic LOEC    
#> 19 1600   NA       Heteromyenia Sponge             sp.          Chronic NOEC    
#> 
#> $anzg_bisphenol_a_marine
#> # A tibble: 8 × 6
#>      Conc Duration Genus              Group          Species    Toxicity_measure
#>     <dbl> <chr>    <chr>              <chr>          <chr>      <chr>           
#> 1  302    72       Prorocentrum       Dinoflagellate cordatum   Chronic EC50    
#> 2 3470    72       Margalefidinium    Dinoflagellate polykriko… Chronic EC50    
#> 3   45.6  920      Hemicentrotus      Echinoderm     pulcherri… Chronic LOEC    
#> 4   38.8  0.5      Paracentrotus      Echinoderm     lividus    Acute EC50      
#> 5   45.3  96       Strongylocentrotus Echinoderm     purpuratus Chronic EC50    
#> 6    0.19 96       Haliotis           Mollusc        diversico… Chronic EC5     
#> 7   20    96       Tigriopus          Crustacean     japonicus  Acute LC50      
#> 8  103    96       Americamysis       Crustacean     bahia      Acute LC50      
#> 
#> $anzg_boron_fresh
#> # A tibble: 22 × 6
#>     Conc Duration Genus        Group     Species   Toxicity_measure
#>    <dbl> <chr>    <chr>        <chr>     <chr>     <chr>           
#>  1  41   7.5      Anaxyrus     Amphibian fowleri   Chronic LC10    
#>  2  29   7.5      Rana         Amphibian pipiens   Chronic LC10    
#>  3  17   7        Carassius    Fish      auratus   Chronic LC10    
#>  4   1.8 34       Danio        Fish      rerio     Chronic NOEC    
#>  5  14   9        Ictalurus    Fish      punctatus Chronic LC10    
#>  6 102   12       Melanotaenia Fish      splendida Chronic LC10    
#>  7   6   11       Micropteris  Fish      salmoides Chronic LC10    
#>  8   6.2 28       Oncorhynchus Fish      mykiss    Chronic LC10    
#>  9  11   32       Pimephales   Fish      promelas  Chronic NOEC    
#> 10   4   52       Cirrhinus    Fish      mrigala   Chronic NOEC    
#> # ℹ 12 more rows
#> 
#> $anzg_chromium_III_fresh
#> # A tibble: 13 × 6
#>     Conc Duration Genus           Group      Species       Toxicity_measure
#>    <dbl> <chr>    <chr>           <chr>      <chr>         <chr>           
#>  1  19   48       Spirostomum     Protozoa   ambiguum      Chronic EC50    
#>  2   3.4 72       Raphidocelis    Microalga  subcapitata   Chronic EC50    
#>  3  10   72       Chlorella       Microalga  kessleri      Chronic EC50    
#>  4 557   72       Dictyosphaerium Microalga  chlorelloides Chronic EC50    
#>  5  82   24       Brachionus      Rotifer    calyciflorus  Acute LC50      
#>  6 128   24       Lecane          Rotifer    quadridentata Acute LC50      
#>  7 330   504      Daphnia         Crustacean magna         Chronic EC16    
#>  8 324   48       Daphnia         Crustacean similis       Acute EC50      
#>  9  48   1,728    Oncorhynchus    Fish       mykiss        Chronic NOEC    
#> 10 333   96       Poecilia        Fish       reticulata    Acute LC50      
#> 11 410   96       Carassius       Fish       auratus       Acute LC50      
#> 12 507   96       Pimephales      Fish       promelas      Acute LC50      
#> 13 746   96       Lepomis         Fish       macrochirus   Acute LC50      
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
#> # A tibble: 28 × 5
#>    Chemical Species                  Conc Group        Units
#>    <chr>    <chr>                   <dbl> <fct>        <chr>
#>  1 Boron    Oncorhynchus mykiss       2.1 Fish         mg/L 
#>  2 Boron    Ictalurus punctatus       2.4 Fish         mg/L 
#>  3 Boron    Micropterus salmoides     4.1 Fish         mg/L 
#>  4 Boron    Brachydanio rerio        10   Fish         mg/L 
#>  5 Boron    Carassius auratus        15.6 Fish         mg/L 
#>  6 Boron    Pimephales promelas      18.3 Fish         mg/L 
#>  7 Boron    Daphnia magna             6   Invertebrate mg/L 
#>  8 Boron    Opercularia bimarginata  10   Invertebrate mg/L 
#>  9 Boron    Ceriodaphnia dubia       13.4 Invertebrate mg/L 
#> 10 Boron    Entosiphon sulcatum      15   Invertebrate mg/L 
#> # ℹ 18 more rows
#> 
#> $ccme_cadmium
#> # A tibble: 36 × 5
#>    Chemical Species                   Conc Group Units
#>    <chr>    <chr>                    <dbl> <fct> <chr>
#>  1 Cadmium  Oncorhynchus mykiss       0.23 Fish  ug/L 
#>  2 Cadmium  Salvelinus confluentus    0.83 Fish  ug/L 
#>  3 Cadmium  Cottus bairdi             0.96 Fish  ug/L 
#>  4 Cadmium  Salmo salar               0.99 Fish  ug/L 
#>  5 Cadmium  Acipenser transmontanus   1.14 Fish  ug/L 
#>  6 Cadmium  Prosopium williamsoni     1.25 Fish  ug/L 
#>  7 Cadmium  Salmo trutta              1.36 Fish  ug/L 
#>  8 Cadmium  Salvelinus fontinalis     2.23 Fish  ug/L 
#>  9 Cadmium  Oncorhynchus tshawytscha  2.29 Fish  ug/L 
#> 10 Cadmium  Pimephales promelas       2.36 Fish  ug/L 
#> # ℹ 26 more rows
#> 
#> $ccme_chloride
#> # A tibble: 28 × 5
#>    Chemical Species                       Conc Group        Units
#>    <chr>    <chr>                        <dbl> <fct>        <chr>
#>  1 Chloride Pimephales promelas            598 Fish         mg/L 
#>  2 Chloride Salmo trutta fario             607 Fish         mg/L 
#>  3 Chloride Oncorhynchus mykiss            989 Fish         mg/L 
#>  4 Chloride Xenopus laevis                1307 Amphibian    mg/L 
#>  5 Chloride Rana pipiens                  3431 Amphibian    mg/L 
#>  6 Chloride Lampsilis fasciola              24 Invertebrate mg/L 
#>  7 Chloride Epioblasma torulosa rangiana    42 Invertebrate mg/L 
#>  8 Chloride Musculium securis              121 Invertebrate mg/L 
#>  9 Chloride Daphnia ambigua                259 Invertebrate mg/L 
#> 10 Chloride Daphnia pulex                  368 Invertebrate mg/L 
#> # ℹ 18 more rows
#> 
#> $ccme_endosulfan
#> # A tibble: 12 × 5
#>    Chemical   Species                            Conc Group        Units
#>    <chr>      <chr>                             <dbl> <fct>        <chr>
#>  1 Endosulfan Oncorhynchus mykiss                0.05 Fish         ng/L 
#>  2 Endosulfan Channa punctata                    0.24 Fish         ng/L 
#>  3 Endosulfan Pimephales promelas                0.28 Fish         ng/L 
#>  4 Endosulfan Hydra vulgaris                     0.06 Invertebrate ng/L 
#>  5 Endosulfan Hydra viridissima                  0.07 Invertebrate ng/L 
#>  6 Endosulfan Daphnia magna                     14.1  Invertebrate ng/L 
#>  7 Endosulfan Ceriodaphnia dubia                14.1  Invertebrate ng/L 
#>  8 Endosulfan Moinodaphnia macleayi             28.3  Invertebrate ng/L 
#>  9 Endosulfan Daphnia cephalata                113.   Invertebrate ng/L 
#> 10 Endosulfan Brachionus calyciflorus         1000    Invertebrate ng/L 
#> 11 Endosulfan Pseudokirchneriella subcapitata  428.   Plant        ng/L 
#> 12 Endosulfan Scenedesmus subspicatus          560    Plant        ng/L 
#> 
#> $ccme_glyphosate
#> # A tibble: 18 × 5
#>    Chemical   Species                           Conc Group        Units
#>    <chr>      <chr>                            <dbl> <fct>        <chr>
#>  1 Glyphosate Oncorhynchus kisutch            130000 Fish         ug/L 
#>  2 Glyphosate Oncorhynchus mykiss             150000 Fish         ug/L 
#>  3 Glyphosate Pimephales promelas              25700 Fish         ug/L 
#>  4 Glyphosate Ceriodaphnia dubia               65000 Invertebrate ug/L 
#>  5 Glyphosate Daphnia magna                    10487 Invertebrate ug/L 
#>  6 Glyphosate Hyalella azteca                  20500 Invertebrate ug/L 
#>  7 Glyphosate Pseudosuccinea columella          3162 Invertebrate ug/L 
#>  8 Glyphosate Anabaena flosaquae               12000 Plant        ug/L 
#>  9 Glyphosate Chlorella pyrenoidosa             3530 Plant        ug/L 
#> 10 Glyphosate Chlorella vulgaris                4696 Plant        ug/L 
#> 11 Glyphosate Lemna gibba                       1587 Plant        ug/L 
#> 12 Glyphosate Myriophyllum sibiricum            1474 Plant        ug/L 
#> 13 Glyphosate Navicula pelliculosa              1800 Plant        ug/L 
#> 14 Glyphosate Potamogeton pectinatus            3162 Plant        ug/L 
#> 15 Glyphosate Pseudokirchneriella subcapitata  10000 Plant        ug/L 
#> 16 Glyphosate Scenedesmus acutus                2820 Plant        ug/L 
#> 17 Glyphosate Scenedesmus obliquus             55858 Plant        ug/L 
#> 18 Glyphosate Scenedesmus quadricauda           1090 Plant        ug/L 
#> 
#> $ccme_silver
#> # A tibble: 9 × 5
#>   Chemical Species                Conc Group        Units
#>   <chr>    <chr>                 <dbl> <fct>        <chr>
#> 1 Silver   Oncorhynchus mykiss    0.24 Fish         ug/L 
#> 2 Silver   Lemna gibba            0.63 Plant        ug/L 
#> 3 Silver   Ceriodaphnia dubia     0.78 Invertebrate ug/L 
#> 4 Silver   Pimephales promelas    0.83 Fish         ug/L 
#> 5 Silver   Ictalurus punctatus    1.9  Fish         ug/L 
#> 6 Silver   Daphnia magna          2.12 Invertebrate ug/L 
#> 7 Silver   Hyalella azteca        4    Invertebrate ug/L 
#> 8 Silver   Chironomus tentans    13    Invertebrate ug/L 
#> 9 Silver   Micropterus salmoides 23    Fish         ug/L 
#> 
#> $ccme_uranium
#> # A tibble: 13 × 5
#>    Chemical Species                          Conc Group        Units
#>    <chr>    <chr>                           <dbl> <fct>        <chr>
#>  1 Uranium  Oncorhynchus mykiss               350 Fish         ug/L 
#>  2 Uranium  Pimephales promelas              1040 Fish         ug/L 
#>  3 Uranium  Esox lucius                      2550 Fish         ug/L 
#>  4 Uranium  Salvelinus namaycush            13400 Fish         ug/L 
#>  5 Uranium  Catostomus commersoni           14300 Fish         ug/L 
#>  6 Uranium  Hyalella azteca                    12 Invertebrate ug/L 
#>  7 Uranium  Ceriodaphnia dubia                 73 Invertebrate ug/L 
#>  8 Uranium  Simocephalus serrulatus           480 Invertebrate ug/L 
#>  9 Uranium  Daphnia magna                     530 Invertebrate ug/L 
#> 10 Uranium  Chironomus tentans                930 Invertebrate ug/L 
#> 11 Uranium  Pseudokirchneriella subcapitata    40 Plant        ug/L 
#> 12 Uranium  Lemna minor                      3100 Plant        ug/L 
#> 13 Uranium  Cryptomonas erosa                 172 Plant        ug/L 
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
```

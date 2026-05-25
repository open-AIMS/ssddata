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
#> $anzg_chlorine_marine
#> # A tibble: 29 × 7
#>      Conc Duration    Genus       Group      Life_stage Species Toxicity_measure
#>     <dbl> <chr>       <chr>       <chr>      <chr>      <chr>   <chr>           
#>  1    6.4 0.003470833 Dendraster  Echinoderm Sperm      excent… Acute EC50      
#>  2   90   0.020833333 Brachionus  Rotifer    Not stated plicat… Acute LC50      
#>  3   23   4           Crassostrea Mollusc    Larva      virgin… Acute LC50      
#>  4   29   4           Acartia     Crustacean Not stated tonsa   Acute LC50      
#>  5  687   4           Pontogeneia Crustacean Adult      sp.     Acute LC50      
#>  6  145   4           Anonyx      Crustacean Adult      sp.     Acute LC50      
#>  7 2890   0.041666667 Homarus     Crustacean Larva      americ… Acute LC50      
#>  8  162   4           Neomysis    Crustacean Adult      sp.     Acute LC50      
#>  9   68   4           Mysidopsis  Crustacean Juvenile   bahia   Acute LC50      
#> 10  178   4           Pandalus    Crustacean Juvenile … danae   Acute LC50      
#> # ℹ 19 more rows
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
#> $anzg_copper_marine
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
#> # ℹ 35 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_dioxins_fresh
#> # A tibble: 8 × 9
#>       Conc Duration Genus        Group Life_stage Notes    Species Test_endpoint
#>      <dbl> <chr>    <chr>        <chr> <chr>      <chr>    <chr>   <chr>        
#> 1 0.000024 132      Cyprinus     Fish  Adult      2,3,7,8… carpio  Mortality    
#> 2 0.0001   15       Esox         Fish  Egg        2,3,7,8… lucius  Mortality    
#> 3 0.00056  64       Oncorhynchus Fish  Juvenile   2,3,7,8… kisutch Mortality    
#> 4 0.000015 56       Oncorhynchus Fish  Fry        2,3,7,8… mykiss  Growth       
#> 5 0.0025   11       Oryzias      Fish  Embryo     2,3,7,8… latipes Mortality    
#> 6 0.00059  7        Pimephales   Fish  Embryo     2,3,7,8… promel… Mortality    
#> 7 0.0009   82       Salvelinus   Fish  Egg        2,3,7,8… fontin… Mortality    
#> 8 0.00125  92       Salvelinus   Fish  Egg        2,3,7,8… namayc… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_diuron_fresh
#> # A tibble: 16 × 8
#>       Conc Duration Genus         Group         Life_stage Species Test_endpoint
#>      <dbl> <chr>    <chr>         <chr>         <chr>      <chr>   <chr>        
#>  1   10.3  4        Achnanthidium Diatom        Planktoni… minuti… Growth rate  
#>  2  315    4        Craticula     Diatom        Planktoni… accomo… Growth rate  
#>  3    4.9  4        Cyclotella    Diatom        Planktoni… menegh… Growth rate  
#>  4   10.4  4        Encyonema     Diatom        Planktoni… silesi… Growth rate  
#>  5 1886    4        Eolimna       Diatom        Planktoni… minima  Growth rate  
#>  6    0.54 4        Fragilaria    Diatom        Planktoni… capuci… Growth rate  
#>  7    7.43 4        Fragilaria    Diatom        Planktoni… rumpens Growth rate  
#>  8   17.6  4        Fragilaria    Diatom        Planktoni… ulna    Growth rate  
#>  9  365    4        Gomphonema    Diatom        Planktoni… parvul… Growth rate  
#> 10   86.5  4        Mayamaea      Diatom        Planktoni… fossal… Growth rate  
#> 11    9.17 3        Navicula      Diatom        Not stated pellic… Biomass yiel…
#> 12  199    4        Nitzschia     Diatom        Planktoni… palea   Growth rate  
#> 13    2.3  3        Scenedesmus   Green alga    Not stated subspi… Biomass yiel…
#> 14    0.44 4        Selenastrum   Green alga    Not stated capric… Biomass yiel…
#> 15    2.49 7        Lemna         Macrophyte    Not stated gibba   Frond number…
#> 16    1.14 3        Synechococcus Cyanobacteria Not stated leopol… Biomass yiel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_diuron_marine
#> # A tibble: 12 × 8
#>     Conc Duration Genus  Group Life_stage Species Test_endpoint Toxicity_measure
#>    <dbl> <chr>    <chr>  <chr> <chr>      <chr>   <chr>         <chr>           
#>  1  1.5  3        Chaet… Diat… Exponenti… muelle… Specific gro… Chronic NEC     
#>  2  2    3        Entom… Diat… Not stated punctu… Cell density  Chronic NOEC    
#>  3  2    3        Nitzs… Diat… Not stated closte… Cell density  Chronic NOEC    
#>  4  2.2  3        Nephr… Gree… Not stated pyrifo… Cell density  Chronic EC10    
#>  5  1.64 3        Tetra… Gree… Exponenti… sp.     Specific gro… Chronic EC10    
#>  6  1.7  3        Rhodo… Cryp… Exponenti… salina  Specific gro… Chronic NEC     
#>  7  2.5  14       Clado… Dino… Exponenti… goreaui Specific gro… Chronic EC10    
#>  8  0.54 3        Emili… Gold… Exponenti… huxleyi Cell density  Chronic NOEC    
#>  9  1.09 3        Isoch… Gold… Not stated galbana Cell density  Chronic EC10    
#> 10  0.6  3        Tisoc… Gold… Exponenti… lutea   Specific gro… Chronic EC10    
#> 11  2.3  15       Sacch… Brow… Thalli     japoni… Fresh weight  Chronic EC10    
#> 12  2.5  10       Zoste… Macr… Not stated marina  Biomass (old… Chronic NOEC    
#> 
#> $anzg_fipronil_fresh
#> # A tibble: 13 × 10
#>     Conc Duration Genus      Group Life_stage Notes Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>      <chr> <chr>      <chr> <chr>  <chr>   <chr>        
#>  1 0.015 2        Cheumatop… Inse… Larvae     Acut… Arthr… brevil… Mortality    
#>  2 0.023 2        Simulium   Inse… Larvae     Acut… Arthr… vittat… Mortality    
#>  3 0.035 1        Culex      Inse… Larvae     Acut… Arthr… quinqu… Mortality    
#>  4 0.042 2        Chironomus Inse… Larvae     Acut… Arthr… crassi… Mortality    
#>  5 0.042 2        Glyptoten… Inse… Larvae     Acut… Arthr… paripes Mortality    
#>  6 0.043 2        Aedes      Inse… Larvae     Acut… Arthr… taenio… Mortality    
#>  7 0.043 2        Anopheles  Inse… Larvae     Acut… Arthr… quadri… Mortality    
#>  8 0.044 4        Hexagenia  Inse… Nymph      Acut… Arthr… sp.     Mortality    
#>  9 0.087 2        Culex      Inse… Larvae     Acut… Arthr… nigrip… Mortality    
#> 10 0.1   2        Polypedil… Inse… Larvae     Acut… Arthr… nubife… Mortality    
#> 11 0.12  1        Aedes      Inse… Larvae     Acut… Arthr… aegypti Mortality    
#> 12 0.245 2        Chironomus Inse… Larvae     Acut… Arthr… annula… Mortality    
#> 13 0.81  2        Aedes      Inse… Larvae     Acut… Arthr… albopi… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_fluoride_fresh
#> # A tibble: 22 × 9
#>     Conc Duration Genus          Group    Life_stage Notes Species Test_endpoint
#>    <dbl> <chr>    <chr>          <chr>    <chr>      <chr> <chr>   <chr>        
#>  1    95 15       Chlorella      Green a… Not stated Valu… vulgar… Growth       
#>  2    50 6.3      Scenedesmus    Green a… Not stated Valu… quadri… Growth       
#>  3   127 3        Scenedesmus    Green a… Not stated Valu… subspi… Growth       
#>  4   195 3        Raphidocelis   Green a… Not stated Valu… subcap… Growth       
#>  5    50 6.3      Ankistrodesmus Green a… Not stated Valu… braunii Growth       
#>  6    50 6.3      Nephroselmis   Green a… Not stated Valu… pyrifo… Growth       
#>  7    50 6.3      Cyclotella     Diatom   Not stated Valu… menegh… Growth       
#>  8    50 6.3      Stephanodiscus Diatom   Not stated Valu… minutus Growth       
#>  9    50 6.3      Oscillatoria   Cyanoba… Not stated Valu… limnet… Growth       
#> 10    25 6.3      Synechococcus  Cyanoba… Not stated Valu… leopol… Growth       
#> # ℹ 12 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_glyphosate_fresh
#> # A tibble: 15 × 9
#>     Conc Duration Genus          Group   Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>          <chr>   <chr>      <chr>  <chr>   <chr>        
#>  1 12000 5        Anabaena       Blue-g… Not stated Cyano… flosaq… Biomass yiel…
#>  2 65000 7        Ceriodaphnia   Crusta… <24-hour … Arthr… dubia   Survival     
#>  3 22500 50       Cherax         Crusta… Advanced … Arthr… quadri… Growth       
#>  4  1082 3        Chlorella      Green … Exponenti… Chlor… saccha… Cell density 
#>  5   450 21       Daphnia        Crusta… Neonate    Arthr… magna   Reproduction 
#>  6 19145 14       Hyalella       Amphip… Juvenile   Arthr… azteca  Survival     
#>  7 12500 21       Lampsilis      Bivalve Juvenile   Mollu… siliqu… Shell length 
#>  8  1400 14       Lemna          Macrop… Not stated Trach… gibba   Frond number…
#>  9  3780 7        Lemna          Macrop… Not stated Trach… minor   Chlorophyll-…
#> 10  1800 5        Navicula       Diatom  Not stated Bacil… pellic… Biomass yiel…
#> 11   316 12       Pseudosuccinea Gastro… Embryo     Mollu… colume… Hatching suc…
#> 12  2000 4        Scenedesmus    Green … Not stated Chlor… acutus  Chlorophyll-…
#> 13   770 4        Scenedesmus    Green … Not stated Chlor… quadri… Chlorophyll-…
#> 14   400 3        Scenedesmus    Green … Exponenti… Chlor… subspi… Cell density 
#> 15 10000 5        Selenastrum    Green … Not stated Chlor… capric… Chlorophyll-…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_iron_fresh
#> # A tibble: 20 × 8
#>     Conc Duration Genus  Group Life_stage Species Test_endpoint Toxicity_measure
#>    <dbl> <chr>    <chr>  <chr> <chr>      <chr>   <chr>         <chr>           
#>  1  6900 21       Alato… Fung… NR         acumin… Growth        Chronic NOEC    
#>  2  6900 21       Artic… Fung… NR         tetrac… Growth        Chronic NOEC    
#>  3  6900 21       Tetra… Fung… NR         elegans Growth        Chronic NOEC    
#>  4   442 3        Raphi… Micr… Not stated subcap… Yield         Chronic EC10    
#>  5  1000 64       Phrag… Macr… Seedling   austra… Growth        Chronic NOEC    
#>  6   957 5        Euchl… Roti… Neonate    dilata… Reproduction  Chronic LC10    
#>  7   470 35       Lumbr… Anne… Worm       varieg… Reproduction  Chronic EC10    
#>  8 40000 30       Duges… Plan… Not stated doroto… Growth        Chronic EC10    
#>  9  7863 30       Hexag… Inse… Nymph      limbata Survival      Chronic EC10    
#> 10 50000 30       Lepto… Inse… Larvae     margin… Immobility    Chronic NOEC    
#> 11   383 7        Cerio… Crus… Neonate    dubia   Reproduction  Chronic EC10    
#> 12  4380 21       Daphn… Crus… Neonate    magna   Reproduction  Chronic EC16    
#> 13   852 21       Daphn… Crus… Neonate    pulex   Reproduction  Chronic NOEC    
#> 14  2607 35       Bufo   Amph… Tadpole    boreas  Biomass       Chronic EC10    
#> 15  3040 7        Oncor… Fish  Larvae     kisutch Mortality     Chronic NOECâ†’…
#> 16 25000 7        Oryzi… Fish  Larvae     latipes Mortality     Chronic NOEC    
#> 17   192 7        Pimep… Fish  Larvae     promel… Growth        Chronic EC10    
#> 18   868 78       Proso… Fish  Egg        willia… Biomass       Chronic EC10    
#> 19  5000 79       Salmo  Fish  Egg        trutta  Biomass       Chronic EC20    
#> 20 10280 245      Salve… Fish  3 months   fontin… Growth        Chronic NOEC    
#> 
#> $anzg_iron_marine
#> # A tibble: 16 × 8
#>     Conc Duration Genus  Group Life_stage Species Test_endpoint Toxicity_measure
#>    <dbl> <chr>    <chr>  <chr> <chr>      <chr>   <chr>         <chr>           
#>  1 50000 4        Isoch… Micr… Not appli… galbana Growth rate … Chronic NOEC    
#>  2 18700 0.229    Acrop… Cnid… Gametes    spathu… Fertilisation Chronic EC10    
#>  3  2750 0.229    Platy… Cnid… Gametes    daedal… Fertilisation Chronic NOEC    
#>  4  2000 3        Helio… Echi… Embryo/la… tuberc… Larval devel… Chronic NOEC    
#>  5   935 2        Anada… Moll… Embryo     trapez… Abnormalities Chronic NEC     
#>  6   893 2        Barnea Moll… Embryo     austra… Abnormalities Chronic NEC     
#>  7   806 2        Fulvia Moll… Embryo     tenuic… Abnormalities Chronic NEC     
#>  8   810 2        Hiatu… Moll… Embryo     alba    Abnormalities Chronic NEC     
#>  9  1020 2        Irus   Moll… Embryo     crenat… Abnormalities Chronic NEC     
#> 10   724 2        Magal… Moll… Embryo     gigas   Abnormalities Chronic NEC     
#> 11   738 2        Sacco… Moll… Embryo     glomer… Abnormalities Chronic NEC     
#> 12  1270 2        Scaeo… Moll… Embryo     livida  Abnormalities Chronic NEC     
#> 13   948 2        Spisu… Moll… Embryo     trigon… Abnormalities Chronic NEC     
#> 14   896 2        Xenos… Moll… Embryo     securis Abnormalities Chronic NEC     
#> 15  4360 2        Halio… Moll… Embryoâ€“… rubra   Normal devel… Chronic EC10    
#> 16  1000 7        Cancer Crus… Embryo     anthon… Hatching      Chronic NOEC    
#> 
#> $anzg_mancozeb_fresh
#> # A tibble: 8 × 9
#>      Conc Duration Genus        Group    Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>        <chr>    <chr>      <chr>  <chr>   <chr>        
#> 1   20    4        Chlorella    Microal… Not stated Chlor… pyreno… Growth       
#> 2  100    4        Chlorella    Microal… Not stated Chlor… vulgar… Growth       
#> 3  100    4        Scenedesmus  Microal… Not stated Chlor… quadri… Growth       
#> 4  100    4        Raphidocelis Microal… Not stated Chlor… subcap… Growth       
#> 5  500    4        Scenedesmus  Microal… Not stated Chlor… obliqu… Growth       
#> 6    7    21       Daphnia      Crustac… Neonate    Arthr… magna   Reproduction 
#> 7 2100    10       Chironomus   Insect   Larvae     Arthr… dilutus Survival     
#> 8    1.35 215      Pimephales   Fish     Larvae     Chord… promel… Growth       
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_manganese_marine
#> # A tibble: 18 × 9
#>      Conc Duration Genus        Group    Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>        <chr>    <chr>      <chr>  <chr>   <chr>        
#>  1  18000 3        Ceratoneis   Diatom   N.A.       Bacil… closte… Growth rate  
#>  2 125000 3        Isochrysis   Golden … Log phase  Hapto… lutea   Growth rate  
#>  3   1090 14       Acropora     Cnidari… Adult      Cnida… millep… Tissue sloug…
#>  4    358 2        Acropora     Cnidari… Adult      Cnida… murica… Tissue sloug…
#>  5    304 2        Acropora     Cnidari… Adult      Cnida… spathu… Tissue sloug…
#>  6  54000 0.229    Platygyra    Cnidari… Gametes    Cnida… daedal… Fertilisation
#>  7    374 2        Stylophora   Cnidari… Adult      Cnida… pistil… Tissue sloug…
#>  8   1580 3        Heliocidaris Echinod… Embryo     Echin… tuberc… Embryo devel…
#>  9   1040 2        Anadara      Mollusc… Embryo     Mollu… trapez… Embryo devel…
#> 10   1780 2        Barnea       Mollusc… Embryo     Mollu… austra… Embryo devel…
#> 11   1460 2        Fulvia       Mollusc… Embryo     Mollu… tenuic… Embryo devel…
#> 12   1520 2        Hiatula      Mollusc… Embryo     Mollu… alba    Embryo devel…
#> 13   2410 2        Irus         Mollusc… Embryo     Mollu… crenat… Embryo devel…
#> 14    650 2        Magallana    Mollusc… Embryo     Mollu… gigas   Embryo devel…
#> 15    654 2        Saccostrea   Mollusc… Embryo     Mollu… glomer… Embryo devel…
#> 16    959 2        Scaeochlamys Mollusc… Embryo     Mollu… livida  Embryo devel…
#> 17   2090 2        Spisula      Mollusc… Embryo     Mollu… trigon… Embryo devel…
#> 18    755 2        Xenostrobus  Mollusc… Embryo     Mollu… securis Embryo devel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_mcpa_fresh
#> # A tibble: 16 × 9
#>        Conc Duration Genus         Group Life_stage Phylum Species Test_endpoint
#>       <dbl> <chr>    <chr>         <chr> <chr>      <chr>  <chr>   <chr>        
#>  1     32   4        Raphidocelis  Gree… Not stated Chlor… subcap… Growth       
#>  2  17020   20       Scenedesmus   Gree… Not stated Chlor… quadri… Growth       
#>  3 143000   3        Desmodesmus   Gree… Not stated Chlor… subspi… Growth       
#>  4    470   5        Anabaena      Blue… Not stated Cyano… flos-a… Growth       
#>  5     14   14       Lemna         Macr… Not stated Trach… gibba   Growth       
#>  6    248   7        Lemna         Macr… Not stated Trach… minor   Growth       
#>  7      7.7 5        Navicula      Diat… Not stated Bacil… pellic… Growth       
#>  8     20   2        Gomphonema    Diat… Not stated Bacil… sp.     Growth       
#>  9     20   2        Encyonema     Diat… Not stated Bacil… gracil… Growth       
#> 10     20   2        Ulnaria       Diat… Not stated Bacil… ulna    Growth       
#> 11    500   2        Gomphonema    Diat… Not stated Bacil… gracile Growth       
#> 12    500   2        Cymbella      Diat… Not stated Bacil… sp.     Growth       
#> 13    500   2        Achnanthidium Diat… Not stated Bacil… minuti… Growth       
#> 14    500   2        Eunotia       Diat… Not stated Bacil… cf. in… Growth       
#> 15    500   2        Navicula      Diat… Not stated Bacil… crypto… Growth       
#> 16  13000   21       Daphnia       Crus… Neonate    Arthr… magna   Immobilisati…
#> # ℹ 1 more variable: Toxicity_measure <chr>
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
#> $anzg_metsulfuron_methyl_fresh
#> # A tibble: 8 × 10
#>        Conc Duration Genus   Group Life_stage Notes Phylum Species Test_endpoint
#>       <dbl> <chr>    <chr>   <chr> <chr>      <chr> <chr>  <chr>   <chr>        
#> 1    95.4   5        Anabae… Blue… Not stated NA    Cyano… flos-a… Biomass yiel…
#> 2     0.054 8        Elodea  Macr… Apical sh… Apic… Trach… canade… Shoot length 
#> 3     0.193 7        Lemna   Macr… Not stated NA    Trach… gibba   Frond count  
#> 4     0.1   42       Lemna   Macr… Exponenti… NA    Trach… minor   Frond count  
#> 5     0.4   14       Myriop… Macr… Apical sh… NA    Trach… spicat… Root occurre…
#> 6 92800     4        Navicu… Diat… Not stated NA    Bacil… pellic… Biomass yiel…
#> 7  4500     90       Oncorh… Fish  Early life NA    Chord… mykiss  Mortality    
#> 8    10     5        Pseudo… Gree… Not stated NA    Chlor… subcap… Biomass yiel…
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nickel_marine
#> # A tibble: 31 × 9
#>       Conc Duration Genus        Group   Life_stage Phylum Species Test_endpoint
#>      <dbl> <chr>    <chr>        <chr>   <chr>      <chr>  <chr>   <chr>        
#>  1  3700   3        Cyanobium    Cyanob… 6 x 10^3 … Cyano… sp.     Growth rate  
#>  2  2870   3        Ceratoneis   Diatom  5-6 d old… Bacil… closte… Growth rate  
#>  3   132   4        Skeletonema  Diatom  Not stated Bacil… costat… Growth       
#>  4 17900   4        Dunaliella   Green … Not stated Chlor… tertio… Growth       
#>  5   250   3        Isochrysis   Brown-… 5-6 d old… Hapto… lutea   Growth rate  
#>  6   310   3        Symbiodinium Dinofl… 6-7 d old… Dinop… sp.     Growth rate  
#>  7   144   10       Champia      Red ma… Adult      Rhodo… parvula Reproduction 
#>  8    96.7 10       Macrocystis  Brown … Zoospore   Phaeo… pyrife… Reproduction 
#>  9     5.5 3.33     Acartia      Crusta… Egg        Arthr… sinjie… Development  
#> 10    67   4        Amphibalanus Crusta… Nauplius   Arthr… amphit… Metamorphosis
#> # ℹ 21 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nitrate_hard_fresh
#> # A tibble: 12 × 9
#>      Conc Duration Genus        Group    Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>        <chr>    <chr>      <chr>  <chr>   <chr>        
#>  1 1600   3        Chlorella    Microal… Exponenti… Chlor… sp.     Growth       
#>  2 1700   3        Oocystis     Microal… Exponenti… Chlor… solita… Growth       
#>  3  220   4        Hydra        Cnidari… Adult      Cnida… viridi… Population g…
#>  4  120   10       Chironomus   Insect   Larvae     Arthr… dilutus Growth weight
#>  5   28.5 7        Ceriodaphnia Crustac… Neonates   Arthr… dubia   Reproduction 
#>  6  358   7        Daphnia      Crustac… Neonates   Arthr… magna   Reproduction 
#>  7  102   14       Hyalella     Crustac… Juvenile   Arthr… azteca  Growth weight
#>  8   45   13       Simocephalus Crustac… Neonates   Arthr… heilon… Reproduction 
#>  9  268   30       Notropis     Fish     Juvenile   Chord… topeka  Growth       
#> 10  335   42       Oncorhynchus Fish     Fry        Chord… mykiss  Growth       
#> 11   46.7 32       Pimephales   Fish     Embryo la… Chord… promel… Growth weight
#> 12   47   52       Hyla         Amphibi… Juvenile   Chord… versic… Metamorphosis
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nitrate_moderate_fresh
#> # A tibble: 11 × 9
#>     Conc Duration Genus        Group     Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>        <chr>     <chr>      <chr>  <chr>   <chr>        
#>  1  17   28       Lampsilis    Mollusc   Juvenile   Mollu… siliqu… Weight       
#>  2   5.8 10       Chironomus   Insect    Larva      Arthr… dilutus Growth weight
#>  3  20.3 20       Deleatidium  Insect    Larva      Arthr… sp.     Mortality    
#>  4  19.4 7        Ceriodaphnia Crustace… Neonates   Arthr… dubia   Reproduction 
#>  5  11   42       Hyalella     Crustace… Juvenile   Arthr… azteca  Growth weight
#>  6 200   29       Danio        Fish      Juvenile   Chord… rerio   Mortality an…
#>  7  26.6 40       Galaxias     Fish      Juvenile   Chord… macula… Mortality    
#>  8  24.9 21       Gobiomorphus Fish      Juvenile   Chord… cotidi… Mortality    
#>  9 120   42       Oncorhynchus Fish      Fry        Chord… mykiss  Yolk develop…
#> 10   6.6 7        Pimephales   Fish      Embryo la… Chord… promel… Growth weight
#> 11  56.7 10       Pseudacris   Amphibian Embryo     Chord… regilla Length       
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_nitrate_soft_fresh
#> # A tibble: 14 × 9
#>     Conc Duration Genus        Group     Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>        <chr>     <chr>      <chr>  <chr>   <chr>        
#>  1 247   3        Raphidocelis Microalga Exponenti… Chlor… subcap… Growth       
#>  2   8.6 60       Sphaerium    Mollusc   Juvenile   Mollu… novaez… Mortality    
#>  3   1.4 40       Potamopyrgus Mollusc   Juvenile   Mollu… antipo… Growth length
#>  4   2.2 60       Paranephrops Crustace… Juvenile   Arthr… planif… Growth length
#>  5   6.3 126      Coregonus    Fish      Embryo al… Chord… clupea… Development  
#>  6   2   40       Galaxias     Fish      Juvenile   Chord… macula… Mortality    
#>  7  22.5 21       Gobiomorphus Fish      Juvenile   Chord… cotidi… Growth weight
#>  8   2.2 30       Oncorhynchus Fish      Fry        Chord… mykiss  Mortality    
#>  9   2.3 30       Oncorhynchus Fish      Fry        Chord… tshawy… Mortality    
#> 10  52   7        Pimephales   Fish      Embryo la… Chord… promel… Growth weight
#> 11   4.5 30       Salmo        Fish      Fry        Chord… clarkii Mortality    
#> 12   1.6 146      Salvelinus   Fish      Embryo al… Chord… namayc… Growth weight
#> 13 117   16       Rana         Amphibian Embryo la… Chord… aurora  Growth weight
#> 14  24.8 10       Xenopus      Amphibian Tadpole    Chord… laevis  Growth weight
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_paraquat_fresh
#> # A tibble: 10 × 9
#>     Conc Duration Genus        Group     Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>        <chr>     <chr>      <chr>  <chr>   <chr>        
#>  1   2.6 4        Oscillatoria Cyanobac… Not stated Cyano… cf. ch… Growth       
#>  2 114   4        Raphidocelis Green al… Not stated Chlor… subcap… Growth       
#>  3   5.1 4        Lemna        Macrophy… Not stated Trach… minor   Growth       
#>  4   1   28       Lemna        Macrophy… Not stated Trach… gibba   Growth       
#>  5  31.8 7        Lemna        Macrophy… Not stated Trach… paucic… Growth       
#>  6  15.2 2        Mesocyclops  Crustace… Nauplii    Arthr… sp.     Mortality    
#>  7  20.7 2        Mesocyclops  Crustace… Nauplii    Arthr… asperi… Mortality    
#>  8 125   2        Daphnia      Crustace… Neonates   Arthr… magna   Immobilisati…
#>  9   8.4 1        Oncorhynchus Fish      Juveniles  Chord… mykiss  Mortality    
#> 10  13.8 5        Xenopus      Amphibian Embryo     Chord… laevis  Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_perfluorooctane_sulfonate_pfos_fresh
#> # A tibble: 37 × 9
#>       Conc Duration Genus        Group   Life_stage Phylum Species Test_endpoint
#>      <dbl> <chr>    <chr>        <chr>   <chr>      <chr>  <chr>   <chr>        
#>  1  2000   30       Bufo         Amphib… Tadpole    Chord… gargar… Mortality    
#>  2    57.6 72       Lithobates   Amphib… Tadpole    Chord… catesb… Growth       
#>  3    10   40       Lithobates   Amphib… Tadpole    Chord… pipiens Development  
#>  4  1250   36       Xenopus      Amphib… Tadpole    Chord… laevis  Growth       
#>  5   590   150      Xenopus      Amphib… Embryo     Chord… tropic… Growth       
#>  6 82000   4        Anabaena     Cyanob… Not stated Cyano… flos-a… Growth and b…
#>  7  6900   6        Ceriodaphnia Crusta… Neonate    Arthr… dubia   Reproduction 
#>  8   400   28       Cyclops      Crusta… Not stated Arthr… diapto… Survival     
#>  9  1000   35       Cyclops      Crusta… Not stated Arthr… cantho… Survival     
#> 10     0.4 21       Daphnia      Crusta… Neonate    Arthr… carina… Reproduction 
#> # ℹ 27 more rows
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_picloram_fresh
#> # A tibble: 12 × 9
#>     Conc Duration Genus        Group     Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>        <chr>     <chr>      <chr>  <chr>   <chr>        
#>  1  8944 4        Raphidocelis Microalga Not stated Chlor… subcap… Growth       
#>  2 10000 4        Chlorella    Microalga Not stated Chlor… vulgar… Growth       
#>  3  1650 4        Gammarus     Crustace… Juvenile   Arthr… pseudo… Mortality    
#>  4  2700 4        Gammarus     Crustace… Adult      Arthr… fascic… Mortality    
#>  5 11800 21       Daphnia      Crustace… Neonate    Arthr… magna   Reproduction 
#>  6  4800 10       Pteronarcys  Insect    YC-2       Arthr… califo… Mortality    
#>  7   140 4        Ictalurus    Fish      Juvenile   Chord… puncta… Mortality    
#>  8   229 4        Oncorhynchus Fish      Juvenile   Chord… clarkii Mortality    
#>  9   236 4        Salvelinus   Fish      Juvenile   Chord… namayc… Mortality    
#> 10   550 60       Oncorhynchus Fish      Embryo     Chord… mykiss  Growth       
#> 11  2226 4        Lepomis      Fish      Juvenile   Chord… macroc… Mortality    
#> 12  5530 4        Pimephales   Fish      Juvenile   Chord… promel… Mortality    
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_simazine_fresh
#> # A tibble: 20 × 9
#>      Conc Duration Genus           Group Life_stage Phylum Species Test_endpoint
#>     <dbl> <chr>    <chr>           <chr> <chr>      <chr>  <chr>   <chr>        
#>  1 1000   21       Daphnia         Arth… Not stated Arthr… magna   Mortality    
#>  2   18   5        Navicula        Diat… Not stated Bacil… pellic… Cell density 
#>  3  171   3        Chlamydomonas   Gree… Exponenti… Chlor… geitle… Growth rate  
#>  4   65   6        Chlorella       Gree… Not stated Chlor… pyreno… Abundance    
#>  5  435   4        Chlorella       Gree… Not stated Chlor… vulgar… Abundance    
#>  6   32   3        Pseudokirchner… Gree… Not stated Chlor… subcap… Growth rate  
#>  7   51.4 4        Scenedesmus     Gree… Not stated Chlor… obliqu… Growth rate  
#>  8   30   4        Scenedesmus     Gree… Not stated Chlor… quadri… Abundance    
#>  9 1000   365      Carassius       Fish  Not stated Chord… auratus Mortality    
#> 10   45   90       Cyprinus        Fish  Not stated Chord… carpio  Weight and m…
#> 11 1000   365      Lepomis         Fish  Not stated Chord… macroc… Mortality    
#> 12  500   28       Oncorhynchus    Fish  Not stated Chord… mykiss  Mortality    
#> 13 1000   120      Pimephales      Fish  Early lif… Chord… promel… Mortality    
#> 14    7.2 5        Anabaena        Cyan… Not stated Cyano… flos-a… Cell density 
#> 15  100   7        Acorus          Macr… Not stated Trach… gramin… Fresh weight 
#> 16   28   14       Lemna           Macr… Not stated Trach… gibba   Biomass yield
#> 17   20   7        Myriophyllum    Macr… 2 weeks o… Trach… aquati… Fresh weight 
#> 18  100   7        Pontederia      Macr… Not stated Trach… cordata Fresh weight 
#> 19  300   7        Typha           Macr… Not stated Trach… latifo… Fresh weight 
#> 20   58   13       Vallisneria     Macr… Not stated Trach… americ… Length       
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_simazine_marine
#> # A tibble: 14 × 9
#>        Conc Duration Genus         Group Life_stage Phylum Species Test_endpoint
#>       <dbl> <chr>    <chr>         <chr> <chr>      <chr>  <chr>   <chr>        
#>  1    310   3        Ceratoneis    Diat… Exponenti… Bacil… closte… Growth rate  
#>  2    400   10       Chlorococcum  Gree… Not stated Chlor… sp.     Cell density 
#>  3   1000   7        Crassostrea   Biva… Spat       Mollu… virgin… Mortality an…
#>  4    257   14       Cladocopium   Dino… Exponenti… Dinof… goreaui Growth rate  
#>  5   1000   10       Dunaliella    Gree… Not stated Chlor… tertio… Cell density 
#>  6    100   10       Isochrysis    Gold… Not stated Hapto… galbana Cell density 
#>  7 100000   4        Neopanope     Crus… Not stated Arthr… texana  Mortality    
#>  8  10000   2        Palaemonetes  Crus… Not stated Arthr… kadiak… Mortality    
#>  9  11300   4        Penaeus       Crus… Not stated Arthr… duorar… Mortality    
#> 10    100   3        Phaeodactylum Diat… Exponenti… Bacil… tricor… Growth rate  
#> 11     38.4 3        Rhodomonas    Cryp… Exponenti… Crypt… salina  Growth rate  
#> 12    250   5        Skeletonema   Diat… Not stated Bacil… costat… Cell density 
#> 13     37.5 3        Tetraselmis   Gree… Exponenti… Chlor… sp.     Growth rate  
#> 14     60.2 3        Tisochrysis   Gold… Exponenti… Hapto… lutea   Growth rate  
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_sulfometuron_methyl_fresh
#> # A tibble: 6 × 9
#>       Conc Duration Genus        Group   Life_stage Phylum Species Test_endpoint
#>      <dbl> <chr>    <chr>        <chr>   <chr>      <chr>  <chr>   <chr>        
#> 1    0.63  5        Raphidocelis Green … Not stated Chlor… subcap… Growth       
#> 2   14     5        Anabaena     Cyanob… Not stated Cyano… flos-a… Growth       
#> 3  370     5        Navicula     Diatom  Not stated Bacil… pellic… Growth       
#> 4    0.207 14       Lemna        Macrop… Not stated Trach… gibba   Growth       
#> 5 6100     21       Daphnia      Crusta… Neonates   Arthr… magna   Reproduction 
#> 6 1000     30       Xenopus      Amphib… Embryos    Chord… laevis  Development  
#> # ℹ 1 more variable: Toxicity_measure <chr>
#> 
#> $anzg_zinc_marine
#> # A tibble: 16 × 9
#>     Conc Duration Genus        Group     Life_stage Phylum Species Test_endpoint
#>    <dbl> <chr>    <chr>        <chr>     <chr>      <chr>  <chr>   <chr>        
#>  1   153 2        Entomoneis   Diatom    Log phase  Ochro… punctu… Population g…
#>  2    84 3        Ceratoneis   Diatom    Log phase  Ochro… closte… Population g…
#>  3    54 3        Dunaliella   Green al… NR         Chlor… tertio… Mortality    
#>  4   143 4        Ulva         Green al… Zoospores  Chlor… fasiata Growth and g…
#>  5  1070 16       Macrocystis  Brown al… Zoospores  Ochro… pyrife… Reproduction 
#>  6    24 4        Hydroides    Annelid   Larvae     Annel… elegans Development  
#>  7     9 28       Aiptasia     Anemone   Adult      Cnida… pulche… Reproduction 
#>  8    62 28       Allorchestes Crustace… Juveniles  Arthr… compre… Mortality    
#>  9   230 14       Callianassa  Crustace… Adult      Arthr… austra… Immobilisati…
#> 10    24 2        Crassostrea  Mollusc   Embryos    Mollu… gigas   Development  
#> 11    64 28       Haliotis     Mollusc   NR         Mollu… divers… Growth       
#> 12     5 2        Mimachlamys  Mollusc   Larvae     Mollu… asperr… Development  
#> 13    35 2        Mytilus      Mollusc   Eggs/Larv… Mollu… edulis  Development  
#> 14    36 2        Mytilus      Mollusc   Embryos    Mollu… gallop… Development  
#> 15    64 2        Mytilus      Mollusc   Embryos    Mollu… trossu… Development  
#> 16  2080 14       Saccostrea   Mollusc   Larvae     Mollu… glomer… Mortality    
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

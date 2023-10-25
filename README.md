# <p align=center>OrthoFinder Nextflow Workflows</p>   

***<p align=center>core</p>***  
```mermaid
flowchart TD
  p0((Channel.fromPath))
    p1[core:coreWorkflow:moveUnambiguousAminoAcidSequencesFirst]
    p2[core:coreWorkflow:orthoFinderSetup]
    p3(( ))
    p4(( ))
    p5(( ))
    p6[core:coreWorkflow:mapCachedBlasts]
    p7([splitText])
    p8([map])
    p9([toList])
    p10([splitText])
    p11([map])
    p12([toList])
    p13([map])
    p14([flatMap])
    p15([groupTuple])
    p16([collect])
    p17([collect])
    p18(( ))
    p19[core:coreWorkflow:diamond]
    p20([collect])
    p21[core:coreWorkflow:computeGroups]
    p22(( ))
    p23([flatten])
    p24([collect])
    p25([collect])
    p26([collect])
    p27(( ))
    p28[core:coreWorkflow:splitOrthologGroupsPerSpecies]
    p29([collect])
    p30[core:coreWorkflow:makeOrthogroupDiamondFiles]
    p31([flatten])
    p32([collectFile])
    p33([collect])
    p34([collect])
    p35[core:coreWorkflow:makeFullSingletonsFile]
    p36[core:coreWorkflow:translateSingletonsFile]
    p37(( ))
    p38[core:coreWorkflow:reformatGroupsFile]
    p39(( ))
    p40([collate])
    p41[core:coreWorkflow:findBestRepresentatives]
    p42([concat])
    p43([flatten])
    p44([collectFile])
    p45[core:coreWorkflow:removeEmptyGroups]
    p46(( ))
    p47[core:coreWorkflow:makeBestRepresentativesFasta]
    p48([splitText])
    p49[core:coreWorkflow:retrieveResultsToBestRepresentative]
    p50([collect])
    p51(( ))
    p52(( ))
    p53[core:coreWorkflow:calculateGroupResults]
    p54(( ))
    p55([splitFasta])
    p56(( ))
    p57[core:coreWorkflow:bestRepsSelfDiamond]
    p58([collectFile])
    p59[core:coreWorkflow:formatSimilarOrthogroups]
    p60(( ))
    p0 -->|inputFile| p1
    p1 --> p2
    p2 --> p3
    p2 --> p16
    p2 --> p6
    p2 --> p6
    p4 -->|previousDiamondCacheDirectory| p6
    p5 -->|outdatedOrganisms| p6
    p6 --> p17
    p2 --> p7
    p7 --> p8
    p8 --> p9
    p9 -->|speciesIds| p13
    p2 --> p10
    p10 --> p11
    p11 --> p12
    p12 -->|speciesNames| p23
    p13 --> p14
    p14 --> p15
    p15 -->|speciesPairsAsTuple| p19
    p16 --> p19
    p17 --> p19
    p18 -->|outputList| p19
    p19 --> p20
    p20 -->|collectedDiamondResults| p21
    p2 -->|orthofinderWorkingDir| p21
    p21 --> p26
    p21 --> p22
    p23 --> p28
    p2 --> p24
    p24 --> p28
    p2 --> p25
    p25 --> p28
    p26 --> p28
    p27 -->|buildVersion| p28
    p28 --> p29
    p28 --> p34
    p29 --> p30
    p15 -->|speciesPairsAsTuple| p30
    p20 -->|collectedDiamondResults| p30
    p30 --> p31
    p31 --> p32
    p32 -->|allDiamondSimilaritiesPerGroup| p33
    p33 -->|allDiamondSimilarities| p49
    p34 -->|singletonFiles| p35
    p35 --> p36
    p2 -->|sequenceMapping| p36
    p36 --> p38
    p21 -->|groupsFile| p38
    p37 -->|buildVersion| p38
    p38 --> p39
    p32 -->|allDiamondSimilaritiesPerGroup| p40
    p40 --> p41
    p41 --> p42
    p35 --> p42
    p42 --> p43
    p43 --> p44
    p44 --> p45
    p45 --> p47
    p2 -->|orthofinderWorkingDir| p47
    p46 -->|isResidual| p47
    p47 --> p55
    p45 --> p48
    p48 --> p49
    p35 -->|singletons| p49
    p49 --> p50
    p50 --> p53
    p51 -->|evalueColumn| p53
    p52 -->|isResidual| p53
    p53 --> p54
    p55 -->|bestRepSubset| p57
    p47 -->|bestRepsFasta| p57
    p56 -->|blastArgs| p57
    p57 --> p58
    p58 --> p59
    p59 --> p60
```
  
***<p align=center>peripheral</p>***  

```mermaid
flowchart TD
  p0((Channel.fromPath))
    p1[peripheral:peripheralWorkflow:uncompressAndMakePeripheralFasta]
    p2(( ))
    p3[peripheral:peripheralWorkflow:uncompressAndMakeCoreFasta]
    p4(( ))
    p5[peripheral:peripheralWorkflow:createDatabase]
    p6(( ))
    p7(( ))
    p8[peripheral:peripheralWorkflow:cleanPeripheralDiamondCache]
    p9([flatten])
    p10(( ))
    p11[peripheral:peripheralWorkflow:peripheralDiamond]
    p12[peripheral:peripheralWorkflow:assignGroups]
    p13([collectFile])
    p14[peripheral:peripheralWorkflow:getPeripheralResultsToBestRep]
    p15([flatten])
    p16([collectFile])
    p17([collect])
    p18(( ))
    p19[peripheral:peripheralWorkflow:combinePeripheralAndCoreSimilaritiesToBestReps]
    p20(( ))
    p21(( ))
    p22[peripheral:peripheralWorkflow:calculatePeripheralGroupResults]
    p23(( ))
    p24[peripheral:peripheralWorkflow:makeResidualAndPeripheralFastas]
    p25[peripheral:peripheralWorkflow:combineProteomes]
    p26(( ))
    p27[peripheral:peripheralWorkflow:makeGroupsFile]
    p28(( ))
    p29[peripheral:peripheralWorkflow:splitProteomeByGroup]
    p30([collect])
    p31([flatten])
    p32([collate])
    p33[peripheral:peripheralWorkflow:keepSeqIdsFromDeflines]
    p34([collect])
    p35([flatten])
    p36([collate])
    p37[peripheral:peripheralWorkflow:createGeneTrees]
    p38(( ))
    p39[peripheral:peripheralWorkflow:createCompressedFastaDir]
    p40[peripheral:peripheralWorkflow:createEmptyBlastDir]
    p41([collect])
    p42[peripheral:peripheralWorkflow:moveUnambiguousAminoAcidSequencesFirst]
    p43[peripheral:peripheralWorkflow:orthoFinderSetup]
    p44(( ))
    p45([splitText])
    p46([map])
    p47([toList])
    p48([splitText])
    p49([map])
    p50([toList])
    p51([map])
    p52([flatMap])
    p53([groupTuple])
    p54([collect])
    p55(( ))
    p56[peripheral:peripheralWorkflow:diamond]
    p57([collect])
    p58[peripheral:peripheralWorkflow:computeGroups]
    p59(( ))
    p60([flatten])
    p61([collect])
    p62([collect])
    p63([collect])
    p64(( ))
    p65[peripheral:peripheralWorkflow:splitOrthologGroupsPerSpecies]
    p66([collect])
    p67[peripheral:peripheralWorkflow:makeOrthogroupDiamondFiles]
    p68([flatten])
    p69([collectFile])
    p70([collect])
    p71([collect])
    p72[peripheral:peripheralWorkflow:makeFullSingletonsFile]
    p73([collate])
    p74[peripheral:peripheralWorkflow:findBestRepresentatives]
    p75([concat])
    p76([flatten])
    p77([collectFile])
    p78[peripheral:peripheralWorkflow:removeEmptyGroups]
    p79(( ))
    p80[peripheral:peripheralWorkflow:makeBestRepresentativesFasta]
    p81([splitText])
    p82[peripheral:peripheralWorkflow:retrieveResultsToBestRepresentative]
    p83(( ))
    p84(( ))
    p85[peripheral:peripheralWorkflow:calculateGroupResults]
    p86(( ))
    p87(( ))
    p88[peripheral:peripheralWorkflow:mergeCoreAndResidualBestReps]
    p89([splitFasta])
    p90([collect])
    p91(( ))
    p92[peripheral:peripheralWorkflow:bestRepsSelfDiamond]
    p93((Channel.fromPath))
    p94([splitFasta])
    p95([collect])
    p96(( ))
    p97[peripheral:peripheralWorkflow:bestRepsSelfDiamondTwo]
    p98([collectFile])
    p99([collectFile])
    p100([concat])
    p101[peripheral:peripheralWorkflow:formatSimilarOrthogroups]
    p102([collectFile])
    p103(( ))
    p104[peripheral:peripheralWorkflow:combineSimilarOrthogroups]
    p105(( ))
    p0 -->|peripheralDir| p1
    p1 --> p9
    p1 --> p24
    p2 -->|coreDir| p3
    p3 --> p25
    p4 -->|newdbfasta| p5
    p5 --> p11
    p6 -->|outdatedOrganisms| p8
    p7 -->|peripheralDiamondCache| p8
    p8 --> p11
    p9 --> p11
    p10 -->|outputList| p11
    p11 --> p12
    p12 --> p13
    p12 --> p14
    p13 -->|groupAssignments| p24
    p12 -->|groupAssignments| p14
    p14 --> p15
    p15 --> p16
    p16 -->|allGroupSimilarityResultsToBestRep| p17
    p17 --> p19
    p18 -->|coreGroupSimilarities| p19
    p19 --> p22
    p20 -->|evalueColumn| p22
    p21 -->|isResidual| p22
    p22 --> p23
    p24 --> p39
    p24 --> p25
    p25 --> p29
    p26 -->|coreGroups| p27
    p13 -->|groupAssignments| p27
    p27 --> p29
    p28 -->|outdated| p29
    p29 --> p30
    p30 --> p31
    p31 --> p32
    p32 --> p33
    p33 --> p34
    p34 --> p35
    p35 --> p36
    p36 --> p37
    p37 --> p38
    p39 --> p42
    p39 -->|-| p40
    p40 --> p41
    p41 -->|emptyDir| p56
    p42 --> p43
    p43 --> p44
    p43 --> p54
    p43 --> p45
    p43 --> p62
    p45 --> p46
    p46 --> p47
    p47 -->|speciesIds| p51
    p43 --> p48
    p48 --> p49
    p49 --> p50
    p50 -->|speciesNames| p60
    p51 --> p52
    p52 --> p53
    p53 -->|pairsChannel| p56
    p54 --> p56
    p55 -->|outputList| p56
    p56 --> p57
    p57 -->|blasts| p58
    p43 -->|orthofinderWorkingDir| p58
    p58 --> p63
    p58 --> p59
    p60 --> p65
    p43 --> p61
    p61 --> p65
    p62 --> p65
    p63 --> p65
    p64 -->|buildVersion| p65
    p65 --> p66
    p65 --> p71
    p66 --> p67
    p53 -->|pairsChannel| p67
    p57 -->|blasts| p67
    p67 --> p68
    p68 --> p69
    p69 -->|allDiamondSimilaritiesPerGroup| p70
    p70 -->|allDiamondSimilarities| p82
    p71 -->|singletonFiles| p72
    p72 --> p75
    p69 -->|allDiamondSimilaritiesPerGroup| p73
    p73 --> p74
    p74 --> p75
    p75 --> p76
    p76 --> p77
    p77 --> p78
    p78 --> p80
    p43 -->|orthofinderWorkingDir| p80
    p79 -->|isResidual| p80
    p80 --> p88
    p78 --> p81
    p81 --> p82
    p72 -->|singletons| p82
    p82 --> p85
    p83 -->|evalueColumn| p85
    p84 -->|isResidual| p85
    p85 --> p86
    p87 -->|coreBestReps.fasta| p88
    p88 --> p90
    p80 --> p89
    p89 -->|bestRepSubset| p92
    p90 --> p92
    p91 -->|blastArgs| p92
    p92 --> p98
    p93 -->|coreBestRepsChannel| p94
    p94 -->|coreBestRepSubset| p97
    p80 --> p95
    p95 --> p97
    p96 -->|blastArgs| p97
    p97 --> p99
    p98 -->|allResidualBestRepsSelfDiamondResults| p100
    p99 -->|allCoreToResidualBestRepsSelfDiamondResults| p100
    p100 --> p101
    p101 --> p102
    p102 --> p104
    p103 -->|coreAndCore| p104
    p104 --> p105
```

**<p align=center>Explanation of Config File Parameters</p>**

| core | peripheral | Parameter | Value | Description |
| ---- | ---- | --------- | ----- | ----------- |
| X  | X | outputDir | string path | Where you would like the output files to be stored |
| X  | X | outdatedOrganisms | string path | Path to the file containing outdated organisms abbrevs (generated with checkForUpdate workflow) |
| X | X | buildVersion | string | Build version number |
| X  |   | proteomes | string path | Compressed directory of core organism fasta files |
| X  |   | diamondSimilarityCache | string path | Path to cache directory of diamond similarity results for the core |
| X  |   | orthoFinderDiamondOutput | string | String of outputs passed to diamond job. This should NOT be changed |
| X  |   | bestRepDiamondOutput | string | String of outputs passed to diamond job. This should NOT be changed |
| X |   | coreProteomes | string path | Path to the input directory of core proteomes |
| X |   | coreBestReps | string path | Path to the best representative file produced by the core workflow |
| X |   | peripheralProteomes | string path | Path to peripheral proteomes |
| X |   | coreGroupsFile | string path | Path to groups file output by core workflow |
| X |   | peripheralDiamondCache | string path | Path to peripheral diamond similarity cache of peripheral to core best rep jobs | 
| X |   | coreSimilarityResults | string path | Path to the group similarity results produced by the core workflow |
| X |   | peripheralDiamondOutput | string | String of outputs passed to diamond job. This should NOT be changed |
| X |   | residualDiamondOutput | string | String of outputs passed to diamond job. This should NOT be changed |
| X |   | coreSimilarOrthogroups | string path | Path to core output file indicating the which groups are similar |

#Devilry-mode

##Om
Devilry-mode gjør det enklere å rette obliger. Når du begynner å rette en oblig åpnes det automatisk en feedback-template, samt de to forrige tilbakemeldingene til studenten hvis disse finnes. Dette gjør at man enkelt kan se studentens utvilkling og dermed gi bedre tilbakemeldinger. Deretter vises README.txt hvis den finnes og alle javafiler kompileres, ved kompileringsfeil vises disse.
Default vil programmet prøve å kompilere alle javafiler i mappen, men dette kan deaktiveres, se "Deaktiver javakompilering".


##Installering
1) Last ned devilry-mode.el og legg den i en passende mappe, for eksemel "~/.emacs.d/plugins/devilry-mode/". Det enkleste er å clone repoet fra mappen "~/.emacs.d/plugins/"

2) Legg følgende linje i .emacsfilen din for å sørge for at devvilry-mode.el blir loadet når emacs starter.

``` elisp
;; Devilry-mode
(add-to-list 'load-path "~/.emacs.d/plugins/devilry-mode/")
(require 'devilry-mode)
```
Hvis du får feilmeldig ved oppstart, kontroller at "devilry-mode.el" ligger i riktig mappe.


##Enkel bruk
- Skriv `M-x devilry-mode` (alt-x) for å aktivere modusen. Scriptet vil prøve å finne filen "devilry-mode.data" (data fra tidligere økter) og eventuelt opprette den hvis den ikke fins.
- Første gangen du bruker devilry-mode må du skrive inn path til et feedback-directory. Her lagres alle tilbakemeldingene dine. Skriv inn pathen. Eksempel: "~/grl/inf1000/h15/feedback/". Skriv så inn path til en feedback-template, dette er en tekstfil som alle tilbakemeldingene vil bruke som mal. Både mappen og tekstfilen vil opprettes dersom de ikke finnes på angitte pather.
- Åpne obligfilene til den første studenten. Det mest effektive er å dra filene over i emacs med musa.
- Trykk f5 (eller skriv "M-x devilry-do-oblig")
- Scriptet finner brukernavnet på en syk måte, kontrollér at det er korrekt.
- Rett obligen!
- f6 lukker alt du har åpent uten å lagre det, bruk dette før du starter på neste oblig.

##Virkemåte
Devilry-mode bruker en feedbackmappe som inneholder én mappe for hver student. Hver gang man gir en tilbakemeldig, blir denne lagret i riktig mappe under navnet "<oblignummer>.txt".
Programmet bruker en fil "devilry-mode.data" for å lagre data fra forrige økt. Denne inneholder path til feedbackmappen, path til feedback-templaten og hviket oblignummer man er på. Hvis denne ikke finnes blir den opprettet ved oppstart av modusen.

##Innstillinger
Alle innstillinger ligger i filen devilry-mode.settings som opprettes samme sted som du installerer devilry-mode første gang du kjører `M-x devilry-mode`.

###Annet mappesystem enn standard devilry-nedlasting (Anbefales!)
[Gard Inge Rosvold](https://github.com/gardir) har laget et [pythonscript](https://github.com/gardir/Devilry_sort) som organiserer mappene lastet ned fra Devilry veldig fint, hvis du har organisert filene slik, må du sette sette variabelen `easy-file-system t`.

###Deaktivering av javakompilering
Sett variabelen `devilry-java-compilation nil`.

###Automatisk indentering
Det er inkludert funksjonalietet for å automatisk indentere all kode riktig når man begynner å rette en ny oblig, men dette anbefales ikke alltid, ettersom studentene trenger trening i å indentere riktig. For å legge til funksjonen: Sett variabelen `automatic-indentation t`.

###Automatisk sletting av .classfiler
Sett variabelen `rm-output-files t`

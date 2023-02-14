
for t in org/Op.*.org
        set tt (basename $t .org).tex
       perl -Mutf8 -CSD  -f scripts/mr2h-script-22.pl $t | perl -Mutf8 -CSD -npe 's/　( [}])$/$1/;s/([^{])[[:blank:]　]{2,}([}])/$1 $2/;' | awk -v RS= 'NR>1 { print ""}NR' > op/$tt
   end

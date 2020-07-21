Note: This repo is largely a snapshop record of bring Wikidata
information in line with Wikipedia, rather than code specifically
deisgned to be reused.

The code and queries etc here are unlikely to be updated as my process
evolves. Later repos will likely have progressively different approaches
and more elaborate tooling, as my habit is to try to improve at least
one part of the process each time around.

---------

Step 1: Check the Position Item
===============================

The Wikidata item for the [Mayor of Nantes](https://www.wikidata.org/wiki/Q19822522)
already has everything we expect — nothing to do here.

Step 2: Tracking page
=====================

PositionHolderHistory page created at https://www.wikidata.org/wiki/Talk:Q19822522

Current status 104 dated officeholders, and 35 dated; 141 warnings.

Step 3: Set up the metadata
===========================

The first step in the repo is always to edit the [add_P39.js script](add_P39.js)
to configure the Item ID and source URL.

Step 4: Get local copy of Wikidata information
==============================================

    wd ee --dry add_P39.js | jq -r '.claims.P39.value' |
      xargs wd sparql office-holders.js | tee wikidata.json

Step 5: Scrape
==============

Comparison/source = [Liste des maires de Nantes](https://fr.wikipedia.org/wiki/Liste_des_maires_de_Nantes)

    wb ee --dry add_P39.js  | jq -r '.claims.P39.references.P4656' |
      xargs bundle exec ruby scraper.rb | tee wikipedia.csv

Took a bit of tweaking to get it to work, mainly because of the awkward
way dates are included, and the shields beside names.

Step 6: Create missing P39s
===========================

    bundle exec ruby new-P39s.rb wikipedia.csv wikidata.json |
      wd ee --batch --summary "Add missing P39s, from $(wb ee --dry add_P39.js | jq -r '.claims.P39.references.P4656')"

11 new additions as officeholders -> https://tools.wmflabs.org/editgroups/b/wikibase-cli/6b88db39e5f95/

Step 7: Add missing qualifiers
==============================

    bundle exec ruby new-qualifiers.rb wikipedia.csv wikidata.json |
      wd aq --batch --summary "Add missing qualifiers, from $(wb ee --dry add_P39.js | jq -r '.claims.P39.references.P4656')"

218 additions made as https://tools.wmflabs.org/editgroups/b/wikibase-cli/6bd745dd8fae3/

Due to almost everyone in the Wikipedia table having only year-precision
dates, there are a *LOT* of warnings, so I'll refresh first and look for
problems before selecting any qualifier updates to apply.

Step 8: Refresh the Tracking Page
=================================

New version: https://www.wikidata.org/w/index.php?title=Talk:Q19822522&oldid=1235666083

Still has quite a few issues to resolve, largely due to only having
year-precision dates for most people, which gets confusing if more than
one person took office in a given year.

Step 9: Qualifier updates
=========================

I tried to resolve lots of these by hand based on info gleaned from the
bios on their frwiki pages, or by setting missing end dates to the same
year as the start dates, where none was supplied.

There was also one case of a successor being to the wrong person with
the same name.

I then also noticed that ordinals were included in the name field on the
frwiki page, so updated the scraper to get those, and then added them as
https://tools.wmflabs.org/editgroups/b/wikibase-cli/448671cca2647

The final version (for now) is at https://www.wikidata.org/w/index.php?title=Talk:Q19822522&oldid=1235766221

Still has 7 warnings, mostly to do with year-precision dates, but that's
a lot better when when I started.

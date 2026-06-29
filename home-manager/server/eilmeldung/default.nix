{ inputs, ... }:
{
  imports = [ inputs.eilmeldung.homeManager.default ];

  programs.eilmeldung.enable = true;

  programs.eilmeldung.settings = {
      # --- Feed List ---
      # All URLs migrated from newsboat
      feed_list = [
        # --- Jobs ---
        "https://academicjobs.fandom.com/api.php?hidebots=1&urlversion=1&days=7&limit=50&action=feedrecentchanges&feedformat=rss"
        "https://academicjobs.fandom.com/wiki/I-School_2025-2026?feed=rss&action=history"
        "https://joblist.mla.org/jobsrss/?Positiontype=20752179&Organizationtype=20752199&Languages=20752056&countrycode=US"
        "https://www.timeshighereducation.com/unijobs/jobsrss/?AcademicDiscipline=513013%2c5%2c20&JobType=32%2c36%2c38%2c39&countrycode=GB"
        "https://www.jobs.ac.uk/jobs/academic-or-research/?format=rss"
        "https://oxide.computer/careers/feed"
        # --- Blogs ---
        "https://drewdevault.com/feed.xml"
        "https://crystaljjlee.com/rss/"
        "https://newleftreview.org/sidecar/feed"
        "https://nplusonemag.com/feed/"
        "https://aisnakeoil.substack.com/feed"
        "https://simonw.substack.com/feed"
        "https://slavoj.substack.com/feed"
        "https://maxread.substack.com/feed"
        "https://weeknotes.ohrg.org/feed.xml"
        "https://ohrg.org/feed.xml"
        "https://anil.recoil.org/news.xml"
        "https://ancazugo.github.io/blog.xml"
        "https://aneeshnaik.github.io/blog.xml"
        "https://arissaelena.github.io/insect-scanner-weeknotes/atom.xml"
        "https://dave.recoil.org/feed.xml"
        "https://digitalflapjack.com/blog/index.xml"
        "https://digitalflapjack.com/weeknotes/index.xml"
        "https://gabrielmahler.org/feed.xml"
        "https://gazagnaire.org/feed.xml"
        "https://jon.recoil.org/atom.xml"
        "https://kcsrk.info/atom.xml"
        "https://mort.io/atom.xml"
        "https://nick.recoil.org/index.xml"
        "https://oppi.li/posts/index.rss"
        "https://oppi.li/weeklies/index.rss"
        "https://parentheticallyspeaking.org/feed.xml"
        "http://patrick.sirref.org/weeklies/atom.xml"
        "https://patrick.sirref.org/ocaml-blog/atom.xml"
        "https://patrick.sirref.org/posts/atom.xml"
        "https://ryan.freumh.org/atom.xml"
        "https://toao.com/feeds/posts.atom.xml"
        "https://www.dra27.uk/feed.xml"
        "https://www.jonmsterling.com/jms-019X/atom.xml"
        "https://www.tunbury.org/atom.xml"
        # --- Tech News ---
        "https://hnrss.org/frontpage?count=100"
        "https://kite.kagi.com/tech.xml"
        "http://rss.slashdot.org/Slashdot/slashdot"
      ];
  };
}

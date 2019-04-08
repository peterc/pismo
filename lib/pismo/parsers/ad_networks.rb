require 'pismo/parsers/base'

module Pismo
  module Parsers
    class AdNetworks < Base
      def call
        matched_networks
      end

      def matched_networks
        @matched_networks ||= html.scan(scanner).flatten.uniq
      end

      def html
        @html ||= doc.to_html
      end

      def scanner
        @scanner ||= Regexp.new(match_regexp)
      end

      def match_regexp
        @match_regexp ||= begin
          match_array.map { |tag| Regexp.escape(tag) }.join('|')
        end
      end

      def match_array
        %w[
            amazon-adsystem.com
            247realmedia.com 360yield.com 3gl.net 3lift.com algovid.com ad-apac.doubleclick.net ad.linksynergy.com ad.pxlad.io adadvisor.net adblade.com adbrn.com adcash.com adform.net adgebra.co.in adglare.net adgrx.com adlog.com.com adlooxtracking.com admantx.com admarketplace.net admeld.com adnxs.com adomik.com adpushup.com adreadytractions.com adrecover.com adroll.com adrta.com adsbyisocket.com adskeeper.co.uk adsnative.com adsonflags.com adspruce.com adsupply.com adsymptotic.com advarkads.com advertising.com adzerk.net affinity.com afsanalytics.com agilone.com aimatch.com airpush.com alexa.com amgdgt.com amung.us andomedia.com angsrvr.com anverlindo.info apnmarketplace.co.nz arlime.com asdorka.com atdmt.com atticwicket.com ayboll.com b.collective-media.net b2c.com bats.video.yahoo.com bc.yahoo.com beaconads.com beap-bc.yahoo.com beap.gemini.yahoo.com bebi.com beemray.com betrad.com beyondd.co.nz bidswitch.net bizographics.com bkrtx.com blitzen.com blockertools.net bluekai.com bluesli.de bnc.lt bnmla.com boomtrain.com botscanner.com bounceexchange.com broadstreetads.com btrll.com bttrack.com btttag.com burstnet.com buysellads.com bzgint.com c.compete.com c.newsinc.com casalemedia.com castplatform.com cedexis.com channelintelligence.com chitika.net clevergirlscollective.com click-server. click-stats23.com click.status.$image clickfuse.com clickiocdnh.com clicktale.net clicktalecdn. codeonclick.com cogocast.net comscore.com connatix.com consumable.com content-ad.net content.ad contextweb.com convertro.com conviva.com cookiex.*/cexposer/SIG= coremetrics.com cosmicwin.com cpx.to cquotient.com/*/gretel. criteo.net$script crowdscience.com crsspxl.com crwdcntrl.net ctnsnet.com cxense.com dashbida.com dashgreen.online decenthat.com delivery47.com demdex.net deployads.com deximedia.com dirt.dennis.co.uk disc.host$image displaymarketplace.com disqus.com/api/ping? disqus.com/get_ dl-rms.com dmtracker.com domdex.com dotomi.com doubleverify.com/*event.gif? dpclk.com dps-reach.com drexel-systems.co dw.com.com ebz.io edigitalsurvey.com effectivemeasure.net eloqua.com$image envy.net eproof.com esearchvision.com eum-appdynamics.com eventlogger. everesttech.net exclusive-gift.online exelator.com exponential.com extreme-dm.com extremereach.io eyeota.net fallingfalcon.com fastclick.net fidelity-media.com firstimpression.io flix360.com fls-*.amazon. flux.com flx1.com fmpub.net fng-ads.fox.com fqtag.com freeskreen.com game-advertising-online.com gcw.mysavings.com geo.yahoo.com getclicky.com getrockerbox.com glanceguide.com go-mpulse.net googleadservices.com googletagservices.com grapeshot.co.uk gravity.com gscontxt.net gscounters. gumgum.com gwallet.com heapanalytics.com histats.com hotjar.com hudb.pl ifmnwi.club igodigital.com imedia.cz img.tfd.com/wn/*32 img.tfd.com/wn/*79 impactradius.com imrworldwide.com indexww.com infolinks.com inside-graph.com inskinad.com intelliad. intellitxt.com intergient.com intermarkets.net intgr.net invoca. ioam.de/tx.io iperceptions.com ipowow.com$image iris.tv isanalyze.com itempana.site jangonetwork.com jscount.com jsrdn.com jwpltx.com keen.io kiip.me kissmetrics.com komoona.com kontera.com korrelate.net krxd.net l.ooyala.com lancheck.net lanistaads.com$image legolas-media.com liadm.com lifestreet.com lijit.com liondigitalserving.com/Tag. liqwid.net liveramp. lkqd.net log. logentries.com lognormal.net lp4.io lytics.io magellan.wayfair.com marchex.io marinsm.com marketgid.com marketingsolutions. marketo.net matheranalytics.com mathtag.com mdadx.com mdotlabs.com mecash.ru media.net media6degrees.com mentad.com mgid.com mixadvert.com mixpanel.com moatads.com monetate.net mookie1.com mosaicolor.website mpstat.us mucocutaneousmyrmecophaga.com mxtads.com myclk.net myvisualiq.net nanigans.com nativeads.com netmng.com netseer.com netshelter.net newpromo. newrelic.com nexac.com novately.com ntv.io odesaconflate.com ohmydating.com olisade.de omarsys.com omnitagjs.com omtrdc.net onclasrv.com onclkds.com online-metrix.net openx. optimahub.com optimize-stats. optimizely.com optimost.com optnmnstr.com oriel.io owlads.io owlanalytics.io owneriq.net oztam.com.au pagead2.*/pagead/ pagefair.com pagefair.net parsely.com partnerads. partnerads1. pebed.dm.gg peer39. perfdrive.com perfectaudience.com perr.h-cdn.com petametrics.com picadmedia.com pictela.net pippio.com pixel. pixfuture.net playnow.guru polarmobile.com popads.net posst.co postrelease.com prizma.tv/get pro-market.net prorentisol.com pubmine.com puserving.com px.reactrmod.com quantserve.com qubitproducts.com questionmarket.com ramp.purch.com recomendedsite.com referrer.disqus.com reinvigorate.net res-x.com researchnow.com reson8.com revdepo.com revsci.net rfihub. richmedia247.com rkdms.com rlcdn.com rover.ebay.com ru4.com rubiconproject.com s.youtube.com$image sa.bbc. sbal4kp.com scorecardresearch.com sekindo.com servedbyopenx.com serving-sys.com shareasale.com silkenthreadiness.info simplereach.com sitemeter.com skimlinks.com skimresources.com sonobi.com spade.twitch.tv specificclick.net spoutable.com springserve.com spylog.ru srpx.net stackadapt.com statcounter.com stats.*.gif? stats0*.gif? statsevent.com statsy.net steelhousemedia.com stirshakead.com summerhamster.com sumome.com$image supert.ag surveygifts.win survicate.com swoop.com taboolasyndication.com tagcade.com tagsrvcs.com teads.tv tealium.hs.llnwd.net telize.com thankswrite.com theadex.com thebloggernetwork.com thefoxads.ru topbananaad.com trace.events trackalyzer.com traq.li trends.revcontent.com tribalfusion.com triggit.com tritondigital.com tru.am truoptik.com tt.onthe.io tubemogul.com turn.com tynt.com typekit.net umbel.com univide.com unrulymedia.com usabilla.com userreport.com vacwrite.com vertamedia.com verymuchad.com video-ad-stats. videostat.com viglink.com vindicosuite.com virool.com visiblemeasures.com visualrevenue.com visualwebsiteoptimizer.com vizury.com w55c.net webspectator.com webtrendslive.com widget.quantcast.com wunderloop.net xg4ken.com xiti.com xpanama.net xtendmedia.com yadro.ru yashi.com yavli.com yieldlab.net yieldmanager. yimg.com/rq/darla/$subdocument,domain=yahoo.com yldbt.com zdbb.net zedo.com ziccardia.com zqtk.net
        ]
      end

      # To simplify updateing this file, load it in ad_networks then you can load and update string
      def from_file
        File.read(File.join(Pismo.root, 'lib', 'pismo', 'config', 'ad_networks.txt'))
      end
    end
  end
end

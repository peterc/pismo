RSpec.describe 'Utils' do
  context 'Hash.deep_find' do
    context 'example1' do
      let(:hsh) do
        {"@context"=>"http://schema.org",
 "@type"=>"NewsArticle",
 "mainEntityOfPage"=>{"@type"=>"WebPage", "@id"=>"https://harwich.wickedlocal.com/entertainmentlife/20190216/simply-delicious-crowd-pleasing-stuffed-shells"},
 "headline"=>"Simply Delicious: Crowd-pleasing stuffed shells",
 "image"=>
  {"@type"=>"ImageObject",
   "url"=>"https://harwich.wickedlocal.com/storyimage/WL/20190216/ENTERTAINMENTLIFE/190219617/AR/0/AR-190219617.jpg",
   "height"=>819,
   "width"=>1020},
 "url"=>"https://harwich.wickedlocal.com/article/20190216/ENTERTAINMENTLIFE/190219617",
 "thumbnailUrl"=>"https://harwich.wickedlocal.com/apps/pbcsi.dll/bilde?Site=WL&Date=20190216&Category=ENTERTAINMENTLIFE&ArtNo=190219617&Ref=AR",
 "dateCreated"=>"20190216T16:21:00Z",
 "datePublished"=>"20190216T16:21:00Z",
 "dateModified"=>"20190211T18:35:00Z",
 "author"=>[{"@type"=>"Person", "name"=>"Laurie Higgins"}],
 "creator"=>"Laurie Higgins",
 "publisher"=>
  {"@type"=>"Organization",
   "name"=>"Harwich Oracle",
   "logo"=>{"@type"=>"ImageObject", "url"=>"https://harwich.wickedlocal.com/Global/images/head/nameplate/harwich_logo.png"}},
 "articleSection"=>"Entertainment & Life",
 "keywords"=>[""],
 "isAccessibleForFree"=>"False",
 "hasPart"=>{"@type"=>"WebPageElement", "isAccessibleForFree"=>"False", "cssSelector"=>".paywall-is-accessible-for-free"}}
      end

      it 'works' do
        expect(Pismo::Utils::HashSearch.deep_find(hsh, 'author')).to be_truthy
        expect(Pismo::Utils::HashSearch.deep_find(hsh, 'author', 'name')).to eq 'Laurie Higgins'
      end
    end

    context 'example2' do
      let(:hsh) do
        [{"@context"=>"http://schema.org",
  "@type"=>"BreadcrumbList",
  "itemListElement"=>
   [{"@type"=>"ListItem", "position"=>1, "item"=>{"@id"=>"https://www.foodandwine.com", "name"=>"Home", "image"=>nil}},
    {"@type"=>"ListItem", "position"=>2, "item"=>{"@id"=>"https://www.foodandwine.com/news", "name"=>"News", "image"=>nil}}]},
 {"@context"=>"http://schema.org",
  "@type"=>"VideoObject",
  "name"=>"McDonald's to Test Non-Plastic Straws in U.S. Locations",
  "description"=>"The chain's restaurants in the U.K. and Ireland have banned plastic straws entirely.",
  "uploadDate"=>"1970-01-01T00:00:00.000Z",
  "duration"=>"PT0M52S",
  "thumbnailUrl"=>
   "https://timeincsecure-a.akamaihd.net/rtmp_uds/1660653193/201806/724/1660653193_5798116514001_5798113518001-vs.jpg?pubId=1660653193&videoId=5798113518001",
  "embedUrl"=>"https://players.brightcove.net/1660653193/default_default/index.html?videoId=5798113518001"},
 {"@context"=>"http://schema.org",
  "@type"=>"Article",
  "headline"=>"Do You Really Need a Sous Vide Precision Cooker? If You've Been on the Fence, Hugh Acheson Will Convince You That You Do",
  "image"=>
   [{"@type"=>"ImageObject",
     "url"=>"https://cdn-image.foodandwine.com/sites/default/files/sous-vide-precision-cooker-ft-blog0618.png",
     "width"=>1008,
     "height"=>756,
     "caption"=>""}],
  "author"=>[{"@type"=>"Person", "name"=>"Elisabeth Sherman"}],
  "publisher"=>
   {"@type"=>"Organization",
    "name"=>"Food & Wine",
    "url"=>"https://www.foodandwine.com",
    "logo"=>{"@type"=>"ImageObject", "url"=>"https://www.foodandwine.com/img/logo.png", "width"=>371, "height"=>60},
    "sameAs"=>
     ["https://www.facebook.com/SportsIllustrated", "https://twitter.com/SInow", "https://www.pinterest.com/", "https://www.instagram.com/sportsillustrated"]},
  "datePublished"=>"2018-06-15T23:28:27.000Z",
  "dateModified"=>"2018-06-18T14:47:27.000Z",
  "description"=>"At the Food & Wine Classic in Aspen, the chef used the tool to churn out fail proof lobster, which we'd like to eat all summer long.",
  "mainEntityOfPage"=>"https://www.foodandwine.com/news/food-and-wine-classic-hugh-acheson-sous-vide-precision-cooker"}]
      end

      it 'works' do
        expect(Pismo::Utils::HashSearch.deep_find(hsh, 'author')).to be_truthy
        expect(Pismo::Utils::HashSearch.deep_find(hsh, 'author', 'name')).to eq 'Elizabeth Sherman'
        binding.pry
      end
    end
  end
end

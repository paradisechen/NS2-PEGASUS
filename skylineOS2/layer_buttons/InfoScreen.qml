// skylineOS 2 — InfoScreen.qml (Nintendo Online & News: Image-Rich Feeds, 4-Way Navigation, Reliable Exit & Non-Colliding Footer)
import QtQuick 2.12
import QtMultimedia 5.9
import QtGraphicalEffects 1.0

FocusScope {
    id: infoRoot
    anchors.fill: parent

    property string sectionMode: "nso" // "nso" = Nintendo Online, "news" = News
    property int catIndex: 0
    property string focusZone: "grid" // "tv" | "cats" | "grid" | "reader"
    property int selectedIndex: 0
    property int gridColumns: 2
    property bool isLoading: false
    property string fetchError: ""

    // Fullscreen Article Reader & News TV State
    property bool readerOpen: false
    property var activeArticle: ({})
    property string readerFullBody: ""
    property string readerFullImage: ""
    property bool readerFetching: false
    property real readerFontScale: 1.5
    property string readerVideoUrl: ""
    property bool videoFullscreen: false
    property bool tvMode: false
    property int tvIndex: 0
    property string activeVideoStreamUrl: ""
    property string activeVideoTitle: ""
    property string activeVideoSource: ""
    property bool videoLoading: false
    property var webVideoObj: null

    property bool isDarkPage: (settings.appearanceMode === "Dark") || (settings.appearanceMode === "Auto" && settings.darkMode === "Yes")
    property color pageBg: isDarkPage ? "#16181D" : "#EFEFEF"
    property color cardBg: isDarkPage ? "#23262F" : "#FFFFFF"
    property color pillBg: isDarkPage ? "#2B2F3A" : "#E5E7EB"
    property color textMain: isDarkPage ? "#F3F4F6" : "#181B20"
    property color textMuted: isDarkPage ? "#B0B7C3" : "#4B5563"
    property color dividerColor: isDarkPage ? "#323642" : "#D1D5DB"

    property string locationCountry: "Puerto Rico"
    property var newsPresets: ["Puerto Rico", "United States", "Mexico", "Spain", "Dominican Republic", "Japan", "United Kingdom"]

    function loadSavedLocationCountry() {
        if (typeof api !== "undefined" && api.memory && api.memory.has("NEWS_LOCATION_COUNTRY")) {
            var savedC = String(api.memory.get("NEWS_LOCATION_COUNTRY") || "").trim();
            if (savedC !== "") locationCountry = savedC;
        }
    }

    function buildLocationUrls(countryName) {
        var c = String(countryName || "Puerto Rico").trim() || "Puerto Rico";
        if (c.toLowerCase() === "puerto rico") {
            return [
                "https://www.metro.pr/arc/outboundfeeds/rss/?outputType=xml",
                "https://www.primerahora.com/arc/outboundfeeds/rss/?outputType=xml",
                "https://www.noticel.com/feed/",
                "https://www.elnuevodia.com/arc/outboundfeeds/rss/category/noticias/locales/?outputType=xml"
            ];
        }
        var isEs = /(spain|espana|españa|mexico|méxico|colombia|argentina|chile|peru|dominican|cuba)/i.test(c);
        var hl = isEs ? "es-419&gl=US&ceid=US:es-419" : "en-US&gl=US&ceid=US:en";
        return [
            "https://www.bing.com/news/search?q=" + encodeURIComponent(c + " news") + "&format=rss",
            "https://news.google.com/rss/search?q=" + encodeURIComponent(c + " news") + "&hl=" + hl
        ];
    }

    function buildNewsCategories() {
        return [
            { id: "latest", label: "Latest News", color: "#E60012", urls: [
                "https://feeds.bbci.co.uk/news/world/rss.xml",
                "https://search.cnbc.com/rs/search/combinedcms/view.xml?partnerId=wrss01&id=100727362"
            ]},
            { id: "location", label: locationCountry, color: "#0284C7", urls: buildLocationUrls(locationCountry) },
            { id: "politics", label: "Politics", color: "#DC2626", urls: [
                "https://feeds.bbci.co.uk/news/politics/rss.xml",
                "https://news.google.com/rss/headlines/section/topic/POLITICS?hl=en-US&gl=US&ceid=US:en"
            ]},
            { id: "economy", label: "Economy", color: "#059669", urls: [
                "https://feeds.bbci.co.uk/news/business/rss.xml",
                "https://search.cnbc.com/rs/search/combinedcms/view.xml?partnerId=wrss01&id=20910258"
            ]},
            { id: "tech", label: "Tech", color: "#7C3AED", urls: [
                "https://www.theverge.com/rss/index.xml",
                "https://feeds.arstechnica.com/arstechnica/index"
            ]},
            { id: "entertainment", label: "Entertainment", color: "#DB2777", urls: [
                "https://variety.com/feed/",
                "https://ew.com/feed/",
                "https://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml"
            ]},
            { id: "sports", label: "Sports", color: "#EA580C", urls: [
                "https://feeds.bbci.co.uk/sport/rss.xml",
                "https://www.skysports.com/rss/12040",
                "https://www.cbssports.com/rss/headlines/",
                "https://sports.yahoo.com/rss/"
            ]},
            { id: "xcom", label: "X.com", color: "#1F2937", urls: [
                "https://news.google.com/rss/search?q=site:x.com+breaking+news&hl=en-US&gl=US&ceid=US:en",
                "https://news.google.com/rss/search?q=site:x.com+trending+tech&hl=en-US&gl=US&ceid=US:en"
            ]}
        ];
    }

    // Nintendo Online Categories (Photo-rich Nintendo outlets + Official Nintendo YouTube videos)
    property var nsoCategories: [
        { id: "nintendo", label: "Nintendo", color: "#E60012", urls: [
            "https://www.nintendolife.com/feeds/latest",
            "https://www.youtube.com/feeds/videos.xml?channel_id=UCGIY_O-8vW4rfX98KlMkvRg",
            "https://nintendoeverything.com/feed/"
        ]},
        { id: "action", label: "Action", color: "#EA580C", urls: [
            "https://www.gematsu.com/feed",
            "https://www.eurogamer.net/feed",
            "https://www.nintendolife.com/feeds/news"
        ]},
        { id: "rpg", label: "RPG", color: "#7C3AED", urls: [
            "https://www.nintendolife.com/feeds/latest",
            "https://www.gematsu.com/feed",
            "https://www.eurogamer.net/feed"
        ]},
        { id: "adventure", label: "Adventure", color: "#0D9488", urls: [
            "https://www.nintendolife.com/feeds/reviews",
            "https://www.eurogamer.net/feed",
            "https://www.gematsu.com/feed"
        ]},
        { id: "indie", label: "Indie", color: "#2563EB", urls: [
            "https://www.nintendolife.com/feeds/news",
            "https://www.rockpapershotgun.com/feed"
        ]},
        { id: "multiplayer", label: "Multiplayer", color: "#DB2777", urls: [
            "https://www.gamespot.com/feeds/news/",
            "https://nintendoeverything.com/feed/",
            "https://www.nintendolife.com/feeds/latest"
        ]}
    ]

    property var newsCategories: buildNewsCategories()
    property var activeCategories: sectionMode === "nso" ? nsoCategories : newsCategories
    property var nsoFallbackCovers: [
        "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/m/mario-kart-8-deluxe-switch/hero",
        "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero",
        "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/m/metroid-prime-remastered-switch/hero",
        "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero"
    ]
    property var newsFallbackCovers: [
        "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/switch-2/hardware/switch-2-hero",
        "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/s/splatoon-3-switch/hero",
        "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/p/pikmin-4-switch/hero",
        "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/s/super-smash-bros-ultimate-switch/hero"
    ]
    property var nsoCuratedFallback: [
        { title: "Nintendo Switch 2 Hardware & Feature Showcase", desc: "Explore Joy-Con 2 magnetic rails, GameChat audio, and 120Hz HDR display.", link: "https://www.nintendo.com/us/gaming-systems/switch-2/", image: "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/m/mario-kart-8-deluxe-switch/hero", fallbackImage: "../assets/images/blurbg.png", hasRealImage: true, hasVideo: true, videoUrl: "dm:x9cgvkm", source: "Nintendo Online", date: "Featured", catColor: "#E60012" },
        { title: "Mario Kart World & Nintendo Classics Catalog", desc: "Race online with GameChat and play GameCube, N64, SNES, and GBA classics.", link: "https://www.nintendolife.com/feeds/latest", image: "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero", fallbackImage: "../assets/images/blurbg.png", hasRealImage: true, hasVideo: true, videoUrl: "dm:x9cgvkm", source: "Nintendo Online", date: "Latest", catColor: "#EA580C" },
        { title: "The Legend of Zelda: Tears of the Kingdom Edition", desc: "Upgraded resolution, instant loading, and expanded cloud saves for members.", link: "https://www.nintendolife.com/feeds/news", image: "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero", fallbackImage: "../assets/images/blurbg.png", hasRealImage: true, hasVideo: false, videoUrl: "", source: "Nintendo Online", date: "Highlight", catColor: "#0D9488" },
        { title: "Metroid Prime & First-Party Action Lineup", desc: "Upcoming action adventures, co-op raids, and indie showcases on eShop.", link: "https://www.gematsu.com/feed", image: "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/m/metroid-prime-remastered-switch/hero", fallbackImage: "../assets/images/blurbg.png", hasRealImage: true, hasVideo: false, videoUrl: "", source: "Nintendo Online", date: "Update", catColor: "#7C3AED" }
    ]
    property var newsCuratedFallback: [
        { title: "Global Technology & Handheld Hardware Roundup", desc: "Latest developments in portable gaming handhelds, high-efficiency SoCs, HDR displays, and mobile cloud streaming standards.", link: "https://www.theverge.com/rss/index.xml", image: "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/m/metroid-prime-remastered-switch/hero", fallbackImage: "../assets/images/blurbg.png", hasRealImage: true, hasVideo: true, videoUrl: "dm:x9cgvkm", source: "Tech News", date: "Latest", catColor: "#7C3AED" },
        { title: "World Markets & Entertainment Headlines", desc: "Top headlines from global wire feeds covering markets, regional updates, film releases, and major sporting events.", link: "https://feeds.bbci.co.uk/news/world/rss.xml", image: "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/m/mario-kart-8-deluxe-switch/hero", fallbackImage: "../assets/images/blurbg.png", hasRealImage: true, hasVideo: true, videoUrl: "dm:x9cgvkm", source: "World News", date: "Live", catColor: "#E60012" },
        { title: "Nintendo Direct & Publishing Schedule", desc: "Upcoming showcase announcements, seasonal tournaments, and multi-platform release updates.", link: "https://www.nintendolife.com/feeds/latest", image: "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/s/super-mario-bros-wonder-switch/hero", fallbackImage: "../assets/images/blurbg.png", hasRealImage: true, hasVideo: true, videoUrl: "dm:x9cgvkm", source: "Entertainment", date: "Featured", catColor: "#DB2777" },
        { title: "Regional & Local Bulletins", desc: "Use Y to set your preferred country or region for tailored local RSS headlines.", link: "https://www.bing.com/news/search?q=world+news&format=rss", image: "https://assets.nintendo.com/image/upload/f_jpg,q_auto,c_scale,w_800/ncom/en_US/games/switch/t/the-legend-of-zelda-tears-of-the-kingdom-switch/hero", fallbackImage: "../assets/images/blurbg.png", hasRealImage: true, hasVideo: false, videoUrl: "", source: "Headlines", date: "Today", catColor: "#0284C7" }
    ]

    ListModel { id: feedModel }
    ListModel { id: readerBlocksModel }

    function openSection(modeStr) {
        loadSavedLocationCountry();
        newsCategories = buildNewsCategories();
        sectionMode = (modeStr === "news") ? "news" : "nso";
        readerOpen = false;
        videoFullscreen = false;
        tvMode = false;
        catIndex = 0;
        focusZone = "grid";
        selectedIndex = 0;
        loadCategory(0, false);
        infoRoot.forceActiveFocus();
        Qt.callLater(function() { infoRoot.forceActiveFocus(); });
    }

    function openLocationPicker() {
        if (sectionMode !== "news") return;
        openSwitchKeyboard(tr("Country / Location News"), infoRoot.locationCountry, false, 60, function(val) {
            var cleanC = String(val || "").trim();
            if (cleanC !== "") {
                infoRoot.locationCountry = cleanC;
                if (typeof api !== "undefined" && api.memory) {
                    api.memory.set("NEWS_LOCATION_COUNTRY", cleanC);
                }
                infoRoot.newsCategories = infoRoot.buildNewsCategories();
                infoRoot.loadCategory(1, true);
            }
            infoRoot.forceActiveFocus();
        }, function() {
            infoRoot.forceActiveFocus();
        });
    }

    function decodeEntities(str) {
        if (!str) return "";
        return String(str)
            .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;|&apos;/g, "'")
            .replace(/&nbsp;/g, " ")
            .replace(/&#(\d+);/g, function(_, n) { return String.fromCharCode(parseInt(n, 10)); });
    }

    function cleanHtml(html) {
        // CRITICAL: unwrap CDATA BEFORE stripping HTML tags so <![CDATA[Title]]> is preserved!
        var unwrapped = String(html || "")
            .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1");
        return decodeEntities(unwrapped
            .replace(/<script[\s\S]*?<\/script>/gi, " ")
            .replace(/<style[\s\S]*?<\/style>/gi, " ")
            .replace(/<[^>]+>/g, " "))
            .replace(/\s+/g, " ")
            .trim();
    }

    function isVideoAssetUrl(url) {
        var u = String(url || "").toLowerCase();
        return /youtube\.com|youtu\.be|vimeo\.com|\.mp4|\.webm|\.m3u8|\.swf/.test(u);
    }

    function toQtImageUrl(rawUrl) {
        var u = decodeEntities(String(rawUrl || "").trim());
        if (u.indexOf("//") === 0) u = "https:" + u;
        if (u.indexOf("http://") !== 0 && u.indexOf("https://") !== 0) return "";
        if (u.indexOf("assets.nintendo.com/image/upload/") !== -1) {
            u = u.replace(/\/f_auto\b/gi, "/f_jpg");
        }
        if (u.indexOf("auto=webp") !== -1) {
            u = u.replace(/([?&])auto=webp(&|$)/gi, "$1").replace(/[?&]$/, "");
            if (u.indexOf("format=") === -1) u += (u.indexOf("?") >= 0 ? "&" : "?") + "format=jpg";
        }
        if (u.indexOf("format=webp") !== -1) {
            u = u.replace(/format=webp/gi, "format=jpg");
        }
        if (/\.(webp|avif)(\?|$)/i.test(u) && u.indexOf("wsrv.nl") === -1) {
            u = "https://wsrv.nl/?url=" + encodeURIComponent(u) + "&output=jpg&w=800&n=-1";
        }
        return u;
    }

    function normalizeImageUrl(raw) {
        var u = decodeEntities(String(raw || "").trim());
        if (u.indexOf("//") === 0) u = "https:" + u;
        if (u.indexOf("http://") !== 0 && u.indexOf("https://") !== 0) return "";
        if (/spacer|1x1|pixel\.gif|doubleclick|blank\.png|favicon|\/site\/icon\/|128x128\.png|gravatar|emoji|badge/i.test(u)) return "";
        if (isVideoAssetUrl(u)) return "";
        return toQtImageUrl(u);
    }

    function shortNsoCardDesc(txt, isNso) {
        var clean = String(txt || "").replace(/Read the full article on [^\s]+/gi, "").replace(/The post .* appeared first on .*/gi, "").replace(/\s+/g, " ").trim();
        if (!isNso) return clean;
        if (clean.length <= 72) return clean;
        var cut = clean.slice(0, 72);
        var sp = cut.lastIndexOf(" ");
        return (sp > 36 ? cut.slice(0, sp) : cut) + "...";
    }

    function extractYouTubeId(text) {
        if (!text) return "";
        var ytTag = String(text).match(/<yt:videoId>([A-Za-z0-9_-]{11})<\/yt:videoId>/i);
        if (ytTag && ytTag[1]) return ytTag[1];
        var ytEmbed = String(text).match(/youtube\.com\/(?:embed\/|watch\?v=|shorts\/)([A-Za-z0-9_-]{11})/i)
                   || String(text).match(/youtu\.be\/([A-Za-z0-9_-]{11})/i);
        return (ytEmbed && ytEmbed[1]) ? ytEmbed[1] : "";
    }

    function extractXmlTag(block, tag) {
        var re = new RegExp("<" + tag + "(?:\\s[^>]*)?>([\\s\\S]*?)<\\/" + tag + ">", "i");
        var m = block.match(re);
        return m ? m[1] : "";
    }

    function extractImage(block, rawHtml) {
        var patterns = [
            /<News:Image>([^<]+)<\/News:Image>/i,
            /<media:thumbnail[^>]+url=["']([^"']+)["']/i,
            /<enclosure[^>]+type=["']image\/[^"']+["'][^>]+url=["']([^"']+)["']/i,
            /<enclosure[^>]+url=["']([^"']+)["'][^>]+type=["']image\/[^"']+["']/i,
            /<itunes:image[^>]+href=["']([^"']+)["']/i,
            /<media:content[^>]+url=["']([^"']+)["']/i,
            /<enclosure[^>]+url=["']([^"']+)["']/i,
            /<img[^>]+data-lazy-src=["']([^"']+)["']/i,
            /<img[^>]+data-src=["']([^"']+)["']/i,
            /<img[^>]+src=["']([^"']+)["']/i
        ];
        var sources = [block || "", rawHtml || ""];
        for (var s = 0; s < sources.length; s++) {
            var src = sources[s];
            for (var p = 0; p < patterns.length; p++) {
                var re = new RegExp(patterns[p].source, "gi");
                var m;
                while ((m = re.exec(src)) !== null) {
                    if (m[1]) {
                        var norm = normalizeImageUrl(m[1]);
                        if (norm !== "") return norm;
                    }
                }
            }
        }
        var ytId = extractYouTubeId((block || "") + " " + (rawHtml || ""));
        if (ytId !== "") return "https://i.ytimg.com/vi/" + ytId + "/hqdefault.jpg";
        return "";
    }

    function parseFeedXml(xmlText, sourceLabel, catColor) {
        var out = [];
        var itemRe = /<(item|entry)\b[\s\S]*?<\/\1>/gi;
        var match;
        var fallPool = (sectionMode === "nso") ? nsoFallbackCovers : newsFallbackCovers;
        while ((match = itemRe.exec(xmlText)) !== null && out.length < 18) {
            var blk = match[0];
            var title = cleanHtml(extractXmlTag(blk, "title"));
            if (!title) continue;
            var link = "";
            var lm = blk.match(/<link[^>]+href=["']([^"']+)["']/i);
            if (lm && lm[1]) link = decodeEntities(lm[1].trim());
            else link = decodeEntities(extractXmlTag(blk, "link")).replace(/<[^>]+>/g, "").trim();

            var rawContent = extractXmlTag(blk, "content:encoded") || extractXmlTag(blk, "media:description") || extractXmlTag(blk, "content") || extractXmlTag(blk, "description") || extractXmlTag(blk, "summary");
            var descText = cleanHtml(rawContent);
            if (/full coverage available|view full coverage/i.test(descText)) {
                descText = title;
            }
            var imgUrl = extractImage(blk, rawContent);
            var hasReal = (imgUrl !== "");
            var fallImg = fallPool[out.length % fallPool.length];
            var ytVidId = extractYouTubeId(blk + " " + rawContent);
            var mp4Match = (blk + " " + rawContent).match(/https?:\/\/[^\s"'<>]+\.(?:mp4|webm|m3u8)(?:\?[^\s"'<>]*)?/i);
            var vidUrl = ytVidId !== "" ? ("yt:" + ytVidId + "|" + title) : (mp4Match ? decodeEntities(mp4Match[0]) : "");
            var pubRaw = cleanHtml(extractXmlTag(blk, "pubDate") || extractXmlTag(blk, "published") || extractXmlTag(blk, "updated"));
            var dateStr = pubRaw ? pubRaw.slice(0, 16) : "Latest";

            out.push({
                title: title,
                desc: descText !== "" ? descText : title,
                link: link,
                image: hasReal ? imgUrl : fallImg,
                fallbackImage: fallImg,
                hasRealImage: hasReal,
                hasVideo: vidUrl !== "",
                videoUrl: vidUrl,
                source: sourceLabel,
                date: dateStr,
                catColor: catColor
            });
        }
        return out;
    }

    function parseRedditJson(jsonText, sourceLabel, catColor) {
        var out = [];
        try {
            var parsed = JSON.parse(jsonText);
            var children = (parsed && parsed.data && parsed.data.children) ? parsed.data.children : [];
            var fallPool = (sectionMode === "nso") ? nsoFallbackCovers : newsFallbackCovers;
            for (var i = 0; i < children.length && out.length < 18; i++) {
                var d = children[i] ? children[i].data : null;
                if (!d || !d.title) continue;
                var img = "";
                if (d.preview && d.preview.images && d.preview.images[0] && d.preview.images[0].source && d.preview.images[0].source.url) {
                    img = normalizeImageUrl(d.preview.images[0].source.url);
                }
                if (!img && d.thumbnail && String(d.thumbnail).indexOf("http") === 0) {
                    img = normalizeImageUrl(d.thumbnail);
                }
                if (img === "" && !d.is_video) continue;
                var body = d.selftext ? cleanHtml(d.selftext) : "";
                if (body === "" && !d.is_video) continue;
                var link = d.permalink ? ("https://www.reddit.com" + d.permalink) : (d.url || "https://www.reddit.com/r/PuertoRico/");
                var fallImg = fallPool[out.length % fallPool.length];
                out.push({
                    title: cleanHtml(d.title),
                    desc: body !== "" ? body : cleanHtml(d.title),
                    link: link,
                    image: img !== "" ? img : fallImg,
                    fallbackImage: fallImg,
                    hasRealImage: img !== "",
                    hasVideo: !!d.is_video,
                    videoUrl: d.is_video && d.url ? String(d.url) : "",
                    source: sourceLabel,
                    date: "Hot",
                    catColor: catColor
                });
            }
        } catch (e) {}
        return out;
    }

    function prefetchMissingImages(catId) {
        var maxHydrate = Math.min(16, feedModel.count);
        for (var i = 0; i < maxHydrate; i++) {
            var item = feedModel.get(i);
            if (!item || item.hasRealImage || !item.link || item.link.indexOf("http") !== 0) continue;
            (function(rowIdx, targetUrl, expectedCat) {
                xhrGetWithTimeout(targetUrl, "text/html,application/xhtml+xml", 4500, function(ok, st, htmlTxt) {
                    var curCatObj = infoRoot.activeCategories[infoRoot.catIndex];
                    if (!curCatObj || curCatObj.id !== expectedCat) return;
                    if (ok && htmlTxt && rowIdx < feedModel.count) {
                        var og = htmlTxt.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i)
                              || htmlTxt.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i)
                              || htmlTxt.match(/<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']/i)
                              || htmlTxt.match(/<img[^>]+class=["'][^"']*(?:hero|featured|cover|wp-post)[^"']*["'][^>]+src=["']([^"']+)["']/i);
                        if (og && og[1]) {
                            var norm = infoRoot.normalizeImageUrl(og[1]);
                            if (norm !== "") {
                                feedModel.setProperty(rowIdx, "image", norm);
                                feedModel.setProperty(rowIdx, "hasRealImage", true);
                            }
                        }
                    }
                });
            })(i, item.link, catId);
        }
    }

    function readFeedCache(cacheKey) {
        if (typeof api === "undefined" || !api.memory || !api.memory.has(cacheKey)) return null;
        try {
            var obj = JSON.parse(String(api.memory.get(cacheKey)));
            if (obj && obj.ts && (Date.now() - obj.ts) < 600000 && Array.isArray(obj.items)) {
                return obj.items;
            }
        } catch (e) {}
        return null;
    }

    function writeFeedCache(cacheKey, itemsArr) {
        if (typeof api === "undefined" || !api.memory || !itemsArr || itemsArr.length === 0) return;
        try {
            api.memory.set(cacheKey, JSON.stringify({ ts: Date.now(), items: itemsArr }));
        } catch (e) {}
    }

    function applyFallbackFeed(catObj) {
        var base = (sectionMode === "nso") ? nsoCuratedFallback : newsCuratedFallback;
        feedModel.clear();
        for (var i = 0; i < base.length; i++) {
            var it = base[i];
            feedModel.append({
                title: it.title,
                desc: it.desc,
                link: it.link,
                image: it.image,
                fallbackImage: it.fallbackImage || "../assets/images/blurbg.png",
                hasRealImage: !!it.hasRealImage,
                hasVideo: !!it.hasVideo,
                videoUrl: it.videoUrl || "",
                source: catObj ? catObj.label : it.source,
                date: it.date,
                catColor: catObj ? catObj.color : it.catColor
            });
        }
        selectedIndex = 0;
    }

    function xhrGetWithTimeout(url, acceptHdr, timeoutMs, onDone) {
        var xhr = new XMLHttpRequest();
        var settled = false;
        var timer = Qt.createQmlObject('import QtQuick 2.12; Timer { interval: ' + (timeoutMs || 4200) + '; repeat: false; running: true }', infoRoot, "xhrTimeout_" + Math.floor(Math.random() * 100000));
        function finish(ok, status, text) {
            if (settled) return;
            settled = true;
            if (timer) { try { timer.stop(); timer.destroy(); } catch (e) {} }
            onDone(ok, status, text);
        }
        if (timer) {
            timer.triggered.connect(function() {
                if (!settled) {
                    try { xhr.abort(); } catch (e) {}
                    finish(false, 0, "");
                }
            });
        }
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || settled) return;
            finish(xhr.status >= 200 && xhr.status < 400 && !!xhr.responseText, xhr.status, xhr.responseText || "");
        };
        xhr.onerror = function() { finish(false, 0, ""); };
        xhr.open("GET", url);
        try { xhr.setRequestHeader("Accept", acceptHdr || "*/*"); } catch (eH) {}
        xhr.send();
    }

    function fetchFromUrls(urls, idx, catObj, feedCacheKey, accumulated) {
        var acc = accumulated || [];
        if (idx >= urls.length || acc.length >= 16) {
            isLoading = false;
            if (acc.length > 0) {
                writeFeedCache(feedCacheKey, acc);
                feedModel.clear();
                for (var j = 0; j < acc.length; j++) feedModel.append(acc[j]);
                selectedIndex = 0;
                prefetchMissingImages(catObj.id);
            } else if (feedModel.count === 0) {
                applyFallbackFeed(catObj);
            }
            fetchError = "";
            return;
        }
        var url = urls[idx];
        var expectedMode = sectionMode;
        var expectedCatIdx = catIndex;
        xhrGetWithTimeout(url, "application/json, application/rss+xml, application/atom+xml, application/xml, text/xml, */*", 4200, function(ok, status, responseText) {
            if (infoRoot.sectionMode !== expectedMode || infoRoot.catIndex !== expectedCatIdx) return;
            if (ok && responseText) {
                var txt = String(responseText).trim();
                var parsed = (url.indexOf(".json") !== -1 || txt.indexOf("{") === 0)
                    ? parseRedditJson(txt, catObj.label, catObj.color)
                    : parseFeedXml(txt, catObj.label, catObj.color);
                if (parsed.length > 0) {
                    var takeCap = (expectedMode === "nso" && idx === 0 && urls.length > 1) ? 8 : 16;
                    for (var p = 0; p < parsed.length && acc.length < 16 && p < takeCap; p++) {
                        acc.push(parsed[p]);
                    }
                    if (expectedMode === "nso" && idx === 0 && urls.length > 1) {
                        fetchFromUrls(urls, idx + 1, catObj, feedCacheKey, acc);
                        return;
                    }
                    writeFeedCache(feedCacheKey, acc);
                    feedModel.clear();
                    for (var k = 0; k < acc.length; k++) feedModel.append(acc[k]);
                    isLoading = false;
                    selectedIndex = 0;
                    prefetchMissingImages(catObj.id);
                    return;
                }
            }
            fetchFromUrls(urls, idx + 1, catObj, feedCacheKey, acc);
        });
    }

    function ensureCategoryVisible() {
        var item = catRepeater.itemAt(catIndex);
        if (!item) return;
        var x1 = item.x;
        var x2 = item.x + item.width;
        if (x1 < catFlick.contentX) catFlick.contentX = Math.max(0, x1 - vpx(12));
        else if (x2 > catFlick.contentX + catFlick.width) catFlick.contentX = Math.min(Math.max(0, catFlick.contentWidth - catFlick.width), x2 - catFlick.width + vpx(12));
    }

    function loadCategory(idx, forceRefresh) {
        var cats = activeCategories;
        if (idx < 0 || idx >= cats.length) return;
        catIndex = idx;
        selectedIndex = 0;
        fetchError = "";
        ensureCategoryVisible();
        var catObj = cats[idx];
        var cacheKey = "FEED_CACHE::" + sectionMode + "::" + catObj.id + "::" + (catObj.id === "location" ? locationCountry.toLowerCase() : "global");
        if (!forceRefresh) {
            var cached = readFeedCache(cacheKey);
            if (cached && cached.length > 0) {
                feedModel.clear();
                for (var c = 0; c < cached.length; c++) feedModel.append(cached[c]);
                isLoading = false;
                return;
            }
        }
        isLoading = true;
        feedModel.clear();
        fetchFromUrls(catObj.urls, 0, catObj, cacheKey, []);
    }

    function fetchFullArticleStory(articleUrl) {
        if (!articleUrl || articleUrl.indexOf("http") !== 0) return;
        var artCacheKey = "ARTICLE_CACHE::" + articleUrl;
        if (typeof api !== "undefined" && api.memory && api.memory.has(artCacheKey)) {
            try {
                var cObj = JSON.parse(String(api.memory.get(artCacheKey)));
                if (cObj && cObj.ts && (Date.now() - cObj.ts) < 600000) {
                    if (cObj.img) readerFullImage = cObj.img;
                    if (cObj.video) {
                        readerVideoUrl = cObj.video;
                        activeArticle = {
                            title: activeArticle.title,
                            desc: activeArticle.desc,
                            link: activeArticle.link,
                            image: activeArticle.image,
                            hasVideo: true,
                            videoUrl: cObj.video,
                            source: activeArticle.source,
                            date: activeArticle.date,
                            catColor: activeArticle.catColor
                        };
                    }
                    if (Array.isArray(cObj.blocks) && cObj.blocks.length > 0) {
                        readerBlocksModel.clear();
                        for (var bi = 0; bi < cObj.blocks.length; bi++) readerBlocksModel.append(cObj.blocks[bi]);
                    }
                    readerFetching = false;
                    return;
                }
            } catch (e) {}
        }
        readerFetching = true;
        var target = articleUrl;
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            readerFetching = false;
            if (xhr.status >= 200 && xhr.status < 400 && xhr.responseText && activeArticle.link === target) {
                var html = xhr.responseText;
                if (!readerFullImage) {
                    var og = html.match(/<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i)
                          || html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i)
                          || html.match(/<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']/i);
                    if (og && og[1]) {
                        var norm = normalizeImageUrl(og[1]);
                        if (norm !== "") readerFullImage = norm;
                    }
                }
                var bodyNoScript = html.replace(/<script[\s\S]*?<\/script>/gi, "").replace(/<style[\s\S]*?<\/style>/gi, "");
                var blockRe = /<p\b[^>]*>([\s\S]*?)<\/p>/gi;
                var blocks = [];
                var paras = [];
                var m;
                while ((m = blockRe.exec(bodyNoScript)) !== null && blocks.length < 28) {
                    var pt = cleanHtml(m[1]);
                    if (pt.length >= 42 && !/cookie|subscribe|sign in|privacy policy|advertisement/i.test(pt)) {
                        paras.push(pt);
                        blocks.push({ kind: "text", text: pt, imgUrl: "" });
                    }
                }
                if (blocks.length > 0) {
                    readerBlocksModel.clear();
                    for (var bi2 = 0; bi2 < blocks.length; bi2++) readerBlocksModel.append(blocks[bi2]);
                }
                if (paras.length >= 1) {
                    readerFullBody = paras.join("\n\n");
                }
                if (readerVideoUrl === "") {
                    var foundYt = extractYouTubeId(html);
                    var foundMp4 = html.match(/https?:\/\/[^\s"'<>]+\.(?:mp4|webm|m3u8)(?:\?[^\s"'<>]*)?/i);
                    if (foundYt !== "") {
                        readerVideoUrl = "https://www.youtube.com/embed/" + foundYt + "?autoplay=1&mute=0&vq=small&playsinline=1&rel=0";
                    } else if (foundMp4 && foundMp4[0]) {
                        readerVideoUrl = foundMp4[0];
                    }
                    if (readerVideoUrl !== "") {
                        activeArticle = {
                            title: activeArticle.title,
                            desc: activeArticle.desc,
                            link: activeArticle.link,
                            image: activeArticle.image,
                            hasVideo: true,
                            videoUrl: readerVideoUrl,
                            source: activeArticle.source,
                            date: activeArticle.date,
                            catColor: activeArticle.catColor
                        };
                    }
                }
                if (typeof api !== "undefined" && api.memory) {
                    try {
                        api.memory.set(artCacheKey, JSON.stringify({
                            ts: Date.now(),
                            img: readerFullImage,
                            video: readerVideoUrl,
                            blocks: blocks
                        }));
                    } catch (eCache) {}
                }
            }
        };
        xhr.open("GET", target);
        xhr.setRequestHeader("Accept", "text/html");
        xhr.send();
    }

    function openArticleAt(idx) {
        if (idx < 0 || idx >= feedModel.count) return;
        selectedIndex = idx;
        newsGrid.currentIndex = idx;
        var item = feedModel.get(idx);
        activeArticle = {
            title: item.title,
            desc: item.desc,
            link: item.link,
            image: item.image,
            hasVideo: !!item.hasVideo || (!!item.videoUrl && item.videoUrl !== ""),
            videoUrl: item.videoUrl || "",
            source: item.source,
            date: item.date,
            catColor: item.catColor
        };
        readerFullImage = item.image || "";
        readerFullBody = item.desc || "";
        readerVideoUrl = item.videoUrl || "";
        readerBlocksModel.clear();
        if (readerFullBody !== "") readerBlocksModel.append({ kind: "text", text: readerFullBody, imgUrl: "" });
        readerOpen = true;
        videoFullscreen = false;
        focusZone = "reader";
        readerFlick.contentY = 0;
        selectSfx.play();
        fetchFullArticleStory(item.link);
        Qt.callLater(function() { readerOverlay.forceActiveFocus(); });
    }

    function nextArticle() {
        if (feedModel.count <= 1) return;
        navSound.play();
        openArticleAt((selectedIndex + 1) % feedModel.count);
    }

    function prevArticle() {
        if (feedModel.count <= 1) return;
        navSound.play();
        openArticleAt((selectedIndex - 1 + feedModel.count) % feedModel.count);
    }

    function cycleReaderTextSize() {
        navSound.play();
        if (readerFontScale < 1.15) readerFontScale = 1.25;
        else if (readerFontScale < 1.40) readerFontScale = 1.5;
        else if (readerFontScale < 1.65) readerFontScale = 1.75;
        else if (readerFontScale < 1.90) readerFontScale = 2.0;
        else readerFontScale = 1.0;
    }

    property int newsPlayerAspectMode: 0 // 0=Fit, 1=16:9, 2=1:1, 3=Fill
    property bool newsPlayerPaused: false
    property bool newsPlayerOsdVisible: true
    property int scrubDir: 0
    property int scrubTicks: 0

    function formatVideoMs(ms) {
        var secs = Math.max(0, Math.floor((ms || 0) / 1000));
        var m = Math.floor(secs / 60);
        var s = secs % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    function bumpNewsPlayerOsd() {
        newsPlayerOsdVisible = true;
        newsOsdHideTimer.restart();
    }

    Timer {
        id: newsOsdHideTimer
        interval: 3800
        repeat: false
        onTriggered: {
            if (!infoRoot.newsPlayerPaused && infoRoot.scrubDir === 0) infoRoot.newsPlayerOsdVisible = false;
        }
    }

    Timer {
        id: newsCassetteScrubTimer
        interval: 65
        repeat: true
        running: infoRoot.scrubDir !== 0 && infoRoot.videoFullscreen && infoRoot.activeVideoStreamUrl !== ""
        onTriggered: {
            infoRoot.scrubTicks += 1;
            var cur = newsFullVideo.position || 0;
            var dur = newsFullVideo.duration || 0;
            var step = Math.min(8000, 1200 + infoRoot.scrubTicks * 350);
            var target = Math.max(0, cur + infoRoot.scrubDir * step);
            if (dur > 0) target = Math.min(dur - 200, target);
            newsFullVideo.seek(target);
            if (!infoRoot.newsPlayerPaused && newsFullVideo.playbackState !== MediaPlayer.PlayingState) {
                newsFullVideo.play();
            }
            infoRoot.bumpNewsPlayerOsd();
        }
    }

    function seekFluidlyTo(targetMs) {
        if (!newsFullVideo || newsFullVideo.duration <= 0) return;
        var clamped = Math.max(0, Math.min(newsFullVideo.duration - 200, Math.round(targetMs)));
        newsFullVideo.seek(clamped);
        if (!newsPlayerPaused && newsFullVideo.playbackState !== MediaPlayer.PlayingState) {
            newsFullVideo.play();
        }
        bumpNewsPlayerOsd();
    }

    function startNewsCassetteScrub(dir) {
        if (scrubDir !== dir) {
            scrubTicks = 0;
            scrubDir = dir;
        }
        if (!newsPlayerPaused && newsFullVideo.playbackState !== MediaPlayer.PlayingState && activeVideoStreamUrl !== "") {
            newsFullVideo.play();
        }
        bumpNewsPlayerOsd();
    }

    function stopNewsCassetteScrub() {
        scrubDir = 0;
        scrubTicks = 0;
        if (!newsPlayerPaused && activeVideoStreamUrl !== "" && newsFullVideo.playbackState !== MediaPlayer.PlayingState) {
            try { newsFullVideo.play(); } catch (e) {}
        }
    }

    function pickSubPlaylistFromMaster(m3u8Text, masterUrl) {
        var lines = String(m3u8Text || "").split(/\r?\n/);
        var baseDir = String(masterUrl || "").replace(/\/[^\/?#]*(?:\?[^#]*)?(?:#.*)?$/, "/");
        var best380 = "";
        var best480 = "";
        var firstUri = "";
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (!line || line.indexOf("#") === 0) continue;
            var abs = line.indexOf("http") === 0 ? line : (baseDir + line.replace(/^\//, ""));
            abs = abs.split("#")[0];
            if (!firstUri) firstUri = abs;
            var prev = i > 0 ? lines[i - 1] : "";
            if (/NAME="380"|x380|640x360|854x480/i.test(prev + " " + abs)) best380 = abs;
            if (/NAME="480"|x480/i.test(prev + " " + abs)) best480 = abs;
        }
        return best380 || best480 || firstUri || String(masterUrl).split("#")[0];
    }

    function destroyWebVideoObj() {
        if (webVideoObj) {
            try { webVideoObj.destroy(); } catch (e) {}
            webVideoObj = null;
        }
    }

    function mountWebVideoFallback(embedUrl) {
        destroyWebVideoObj();
        activeVideoStreamUrl = "";
        newsFullVideo.stop();
        videoLoading = false;
        var candidates = [
            "import QtQuick 2.12; import QtWebView 1.1; WebView { anchors.fill: parent }",
            "import QtQuick 2.12; import QtWebView 1.0; WebView { anchors.fill: parent }",
            "import QtQuick 2.12; import QtWebView 1.15; WebView { anchors.fill: parent }",
            "import QtQuick 2.12; import QtWebEngine 1.8; WebEngineView { anchors.fill: parent }"
        ];
        for (var i = 0; i < candidates.length; i++) {
            try {
                var o = Qt.createQmlObject(candidates[i], newsVideoHost, "newsWeb_" + i);
                if (o) {
                    o.url = String(embedUrl);
                    webVideoObj = o;
                    return true;
                }
            } catch (e) {}
        }
        return false;
    }

    function mountNativeNewsVideo(streamUrl) {
        destroyWebVideoObj();
        if (!streamUrl || streamUrl === "") return;
        var cleanSrc = String(streamUrl).split("#")[0].replace(/"/g, "");
        activeVideoStreamUrl = cleanSrc;
        videoLoading = false;
        newsPlayerPaused = false;
        bumpNewsPlayerOsd();
        Qt.callLater(function() {
            try { newsFullVideo.play(); } catch (e) {}
        });
    }

    function toggleNewsVideoPlayPause() {
        if (activeVideoStreamUrl === "") return;
        if (newsPlayerPaused || newsFullVideo.playbackState !== MediaPlayer.PlayingState) {
            newsPlayerPaused = false;
            newsFullVideo.play();
        } else {
            newsPlayerPaused = true;
            newsFullVideo.pause();
        }
        bumpNewsPlayerOsd();
    }

    function resolveSteamNewsFallback(queryText, reqId) {
        var cleanQ = String(queryText || "").replace(/[^A-Za-z0-9\s]/g, " ").replace(/\s+/g, " ").trim();
        if (!cleanQ) cleanQ = "Nintendo Switch";
        xhrGetWithTimeout("https://store.steampowered.com/api/storesearch/?term=" + encodeURIComponent(cleanQ) + "&l=english&cc=US", "application/json", 3200, function(ok, st, txt) {
            if (!infoRoot.videoFullscreen || reqId !== infoRoot.videoReqCounter) return;
            if (ok) {
                try {
                    var sj = JSON.parse(txt);
                    var items = (sj && sj.items) ? sj.items : [];
                    if (items.length > 0 && items[0] && items[0].id) {
                        var appId = String(items[0].id);
                        xhrGetWithTimeout("https://store.steampowered.com/api/appdetails?appids=" + encodeURIComponent(appId), "application/json", 3200, function(ok2, st2, txt2) {
                            if (!infoRoot.videoFullscreen || reqId !== infoRoot.videoReqCounter) return;
                            try {
                                var aj = JSON.parse(txt2);
                                var appData = aj && aj[appId] && aj[appId].data ? aj[appId].data : null;
                                var movies = appData && Array.isArray(appData.movies) ? appData.movies : [];
                                if (movies.length > 0) {
                                    var mv = movies[0];
                                    var mp4 = (mv.mp4 && (mv.mp4["480"] || mv.mp4.max)) ? String(mv.mp4["480"] || mv.mp4.max) : (mv.hls_h264 ? String(mv.hls_h264) : "");
                                    if (mp4 !== "") {
                                        infoRoot.mountNativeNewsVideo(mp4);
                                        return;
                                    }
                                }
                            } catch (e2) {}
                            infoRoot.resolveDailymotionById("x9cgvkm", reqId);
                        });
                        return;
                    }
                } catch (e) {}
            }
            infoRoot.resolveDailymotionById("x9cgvkm", reqId);
        });
    }

    property int videoReqCounter: 0

    function resolveDailymotionById(dmId, reqId) {
        if (!dmId) return;
        xhrGetWithTimeout("https://www.dailymotion.com/player/metadata/video/" + encodeURIComponent(dmId), "application/json", 3800, function(ok, st, txt) {
            if (!infoRoot.videoFullscreen || reqId !== infoRoot.videoReqCounter) return;
            if (ok) {
                try {
                    var meta = JSON.parse(txt);
                    var q = meta && meta.qualities ? meta.qualities : null;
                    var directFast = "";
                    var masterHls = "";
                    if (q && Array.isArray(q["380"]) && q["380"].length > 0 && q["380"][0].url) {
                        directFast = String(q["380"][0].url).split("#")[0];
                    } else if (q && Array.isArray(q["480"]) && q["480"].length > 0 && q["480"][0].url) {
                        directFast = String(q["480"][0].url).split("#")[0];
                    }
                    if (q && Array.isArray(q.auto) && q.auto.length > 0 && q.auto[0].url) {
                        masterHls = String(q.auto[0].url).split("#")[0];
                    }
                    if (directFast !== "" && directFast.indexOf(".mp4") >= 0) {
                        infoRoot.mountNativeNewsVideo(directFast);
                        return;
                    }
                    var manifest = directFast || masterHls;
                    if (manifest !== "") {
                        xhrGetWithTimeout(manifest, "*/*", 3500, function(okP, stP, txtP) {
                            if (!infoRoot.videoFullscreen || reqId !== infoRoot.videoReqCounter) return;
                            if (okP && txtP && txtP.indexOf("#EXT-X-STREAM-INF") >= 0) {
                                infoRoot.mountNativeNewsVideo(infoRoot.pickSubPlaylistFromMaster(txtP, manifest));
                            } else {
                                infoRoot.mountNativeNewsVideo(manifest);
                            }
                        });
                        return;
                    }
                } catch (em) {}
            }
            infoRoot.mountWebVideoFallback("https://www.dailymotion.com/embed/video/" + encodeURIComponent(dmId) + "?autoplay=1");
        });
    }

    function resolveDailymotionNewsStream(queryText, reqId) {
        var cleanQ = String(queryText || "").replace(/[^A-Za-z0-9\s]/g, " ").replace(/\s+/g, " ").trim();
        if (!cleanQ) cleanQ = "world news highlights";
        var words = cleanQ.split(" ").slice(0, 6).join(" ");
        xhrGetWithTimeout("https://api.dailymotion.com/videos?search=" + encodeURIComponent(words) + "&fields=id,title&limit=4&sort=relevance", "application/json", 3800, function(ok, st, txt) {
            if (!infoRoot.videoFullscreen || reqId !== infoRoot.videoReqCounter) return;
            if (ok && txt) {
                try {
                    var res = JSON.parse(txt);
                    var list = (res && res.list) ? res.list : [];
                    if (list.length > 0 && list[0].id) {
                        infoRoot.resolveDailymotionById(String(list[0].id), reqId);
                        return;
                    }
                } catch (e) {}
            }
            xhrGetWithTimeout("https://api.dailymotion.com/videos?search=" + encodeURIComponent(infoRoot.sectionMode === "nso" ? "Nintendo Switch 2 trailer" : "breaking news report") + "&fields=id,title&limit=3&sort=recent", "application/json", 3400, function(ok2, st2, txt2) {
                if (!infoRoot.videoFullscreen || reqId !== infoRoot.videoReqCounter) return;
                if (ok2 && txt2) {
                    try {
                        var res2 = JSON.parse(txt2);
                        var list2 = (res2 && res2.list) ? res2.list : [];
                        if (list2.length > 0 && list2[0].id) {
                            infoRoot.resolveDailymotionById(String(list2[0].id), reqId);
                            return;
                        }
                    } catch (e2) {}
                }
                infoRoot.resolveSteamNewsFallback(cleanQ, reqId);
            });
        });
    }

    function mountFullscreenNewsVideoUrl(targetVideoUrl, titleText, sourceLabel) {
        videoReqCounter += 1;
        var reqId = videoReqCounter;
        destroyWebVideoObj();
        newsFullVideo.stop();
        activeVideoStreamUrl = "";
        videoLoading = true;
        activeVideoTitle = titleText || (activeArticle && activeArticle.title ? activeArticle.title : "News Broadcast");
        activeVideoSource = sourceLabel || (activeArticle && activeArticle.source ? activeArticle.source : "News TV");

        var cleanUrl = String(targetVideoUrl || "").trim();
        if (cleanUrl.indexOf("dm:") === 0) {
            resolveDailymotionById(cleanUrl.slice(3), reqId);
            return;
        }
        if (cleanUrl.indexOf("yt:") === 0) {
            var qPart = cleanUrl.split("|").slice(1).join("|");
            resolveDailymotionNewsStream(qPart || activeVideoTitle, reqId);
            return;
        }
        if (/\.(mp4|webm|m4v|m3u8)(\?|$)/i.test(cleanUrl)) {
            mountNativeNewsVideo(cleanUrl);
            return;
        }
        resolveDailymotionNewsStream(activeVideoTitle, reqId);
    }

    function openNewsVideoFullscreen() {
        var v = readerVideoUrl || (activeArticle ? activeArticle.videoUrl : "");
        if (!v || v === "") v = activeArticle ? activeArticle.title : "Nintendo Switch 2";
        tvMode = false;
        videoFullscreen = true;
        newsPlayerAspectMode = 0;
        newsPlayerPaused = false;
        stopNewsCassetteScrub();
        selectSfx.play();
        mountFullscreenNewsVideoUrl(v, activeArticle ? activeArticle.title : "", activeArticle ? activeArticle.source : "");
        bumpNewsPlayerOsd();
        Qt.callLater(function() { newsVideoOverlay.forceActiveFocus(); });
    }

    function openNewsTvMode(startIdx) {
        if (feedModel.count === 0) return;
        var idx = (typeof startIdx === "number" && startIdx >= 0 && startIdx < feedModel.count) ? startIdx : selectedIndex;
        if (idx < 0 || idx >= feedModel.count) idx = 0;
        tvMode = true;
        tvIndex = idx;
        videoFullscreen = true;
        newsPlayerAspectMode = 0;
        newsPlayerPaused = false;
        stopNewsCassetteScrub();
        selectSfx.play();
        var item = feedModel.get(idx);
        activeArticle = {
            title: item.title,
            desc: item.desc,
            link: item.link,
            image: item.image,
            hasVideo: true,
            videoUrl: item.videoUrl || "",
            source: item.source,
            date: item.date,
            catColor: item.catColor
        };
        readerFullImage = item.image || "";
        mountFullscreenNewsVideoUrl(item.videoUrl || item.title, item.title, item.source);
        bumpNewsPlayerOsd();
        Qt.callLater(function() { newsVideoOverlay.forceActiveFocus(); });
    }

    function stepTvVideo(delta) {
        if (feedModel.count === 0) return;
        var nextIdx = (tvIndex + delta + feedModel.count) % feedModel.count;
        navSound.play();
        openNewsTvMode(nextIdx);
    }

    function closeNewsVideoFullscreen() {
        videoFullscreen = false;
        tvMode = false;
        videoLoading = false;
        activeVideoStreamUrl = "";
        newsFullVideo.stop();
        destroyWebVideoObj();
        backSfx.play();
        if (readerOpen) {
            readerOverlay.forceActiveFocus();
        } else {
            infoRoot.forceActiveFocus();
            Qt.callLater(function() { infoRoot.forceActiveFocus(); });
        }
    }

    function closeReader() {
        readerOpen = false;
        focusZone = "grid";
        backSfx.play();
        infoRoot.forceActiveFocus();
        Qt.callLater(function() { infoRoot.forceActiveFocus(); });
    }

    function exitScreen() {
        backSfx.play();
        showHomeScreen();
    }

    function openExternalArticle() {
        if (!activeArticle || !activeArticle.link) return;
        selectSfx.play();
        if (settings.browserMode === "chrome") Qt.openUrlExternally(activeArticle.link);
        else openInThemeBrowser(activeArticle.link);
    }

    function isBackEvent(event) {
        return api.keys.isCancel(event) || event.key === Qt.Key_Escape || event.key === Qt.Key_Backspace || event.key === Qt.Key_B;
    }

    onVisibleChanged: {
        if (visible) {
            if (feedModel.count === 0 && !isLoading) loadCategory(catIndex);
            infoRoot.forceActiveFocus();
            Qt.callLater(function() { infoRoot.forceActiveFocus(); });
        } else {
            if (videoFullscreen) closeNewsVideoFullscreen();
        }
    }

    Keys.onLeftPressed: {
        if (videoFullscreen || readerOpen) return;
        navSound.play();
        if (focusZone === "cats") {
            if (catIndex === 0 && sectionMode === "news") {
                focusZone = "tv";
            } else {
                var prevCat = (catIndex - 1 + activeCategories.length) % activeCategories.length;
                loadCategory(prevCat);
            }
        } else if (focusZone === "tv") {
            focusZone = "cats";
            loadCategory(activeCategories.length - 1);
        } else if (feedModel.count > 0) {
            selectedIndex = (selectedIndex - 1 + feedModel.count) % feedModel.count;
            newsGrid.currentIndex = selectedIndex;
            newsGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
        }
    }

    Keys.onRightPressed: {
        if (videoFullscreen || readerOpen) return;
        navSound.play();
        if (focusZone === "tv") {
            focusZone = "cats";
            loadCategory(0);
        } else if (focusZone === "cats") {
            var nextCat = (catIndex + 1) % activeCategories.length;
            loadCategory(nextCat);
        } else if (feedModel.count > 0) {
            selectedIndex = (selectedIndex + 1) % feedModel.count;
            newsGrid.currentIndex = selectedIndex;
            newsGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
        }
    }

    Keys.onUpPressed: {
        if (videoFullscreen || readerOpen) return;
        navSound.play();
        if (focusZone === "grid") {
            if (selectedIndex < gridColumns) {
                focusZone = "cats";
                ensureCategoryVisible();
            } else {
                selectedIndex = Math.max(0, selectedIndex - gridColumns);
                newsGrid.currentIndex = selectedIndex;
                newsGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
            }
        } else if (focusZone === "cats" && sectionMode === "news") {
            focusZone = "tv";
        }
    }

    Keys.onDownPressed: {
        if (videoFullscreen || readerOpen) return;
        navSound.play();
        if (focusZone === "tv") {
            focusZone = "cats";
            ensureCategoryVisible();
        } else if (focusZone === "cats") {
            focusZone = "grid";
            selectedIndex = 0;
            newsGrid.currentIndex = 0;
            newsGrid.positionViewAtIndex(0, GridView.Contain);
        } else if (feedModel.count > 0) {
            selectedIndex = Math.min(feedModel.count - 1, selectedIndex + gridColumns);
            newsGrid.currentIndex = selectedIndex;
            newsGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
        }
    }

    Keys.onBackPressed: {
        event.accepted = true;
        if (videoFullscreen) { closeNewsVideoFullscreen(); return; }
        readerOpen = false;
        focusZone = "grid";
        exitScreen();
    }

    Keys.onEscapePressed: {
        event.accepted = true;
        if (videoFullscreen) closeNewsVideoFullscreen();
        else if (readerOpen) closeReader();
        else exitScreen();
    }
    Keys.onReleased: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
            root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
        if (!event.isAutoRepeat) stopNewsCassetteScrub();
    }

    Keys.onPressed: {
        if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) { event.accepted = true; return; }
        if (videoFullscreen) return;
        if (readerOpen) {
            if (isBackEvent(event) && !event.isAutoRepeat) {
                event.accepted = true;
                closeReader();
            }
            return;
        }
        if (api.keys.isAccept(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (focusZone === "tv") {
                openNewsTvMode(selectedIndex);
            } else if (focusZone === "cats") {
                focusZone = "grid";
                selectedIndex = 0;
                newsGrid.currentIndex = 0;
                selectSfx.play();
            } else {
                openArticleAt(selectedIndex);
            }
        } else if (event.key === Qt.Key_T && !event.isAutoRepeat) {
            event.accepted = true;
            openNewsTvMode(selectedIndex);
        } else if (isBackEvent(event) && !event.isAutoRepeat) {
            event.accepted = true;
            if (focusZone === "cats" || focusZone === "tv") {
                focusZone = "grid";
                backSfx.play();
            } else {
                exitScreen();
            }
        } else if ((api.keys.isFilters(event) || event.key === Qt.Key_X) && !event.isAutoRepeat) {
            event.accepted = true;
            navSound.play();
            loadCategory(catIndex, true);
        } else if ((api.keys.isDetails(event) || event.key === Qt.Key_Y) && !event.isAutoRepeat) {
            if (sectionMode === "news") {
                event.accepted = true;
                openLocationPicker();
            }
        } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            navSound.play();
            loadCategory((catIndex + 1) % activeCategories.length, false);
        } else if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            navSound.play();
            loadCategory((catIndex - 1 + activeCategories.length) % activeCategories.length, false);
        }
    }

    Rectangle { anchors.fill: parent; color: infoRoot.pageBg }

    // Top Header
    Item {
        id: infoHeader
        anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.108)

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: vpx(14)
            Image {
                width: vpx(30); height: vpx(30)
                source: infoRoot.sectionMode === "nso" ? "../assets/images/navigation/ns2_online.svg" : "../assets/images/navigation/ns2_news.svg"
                fillMode: Image.PreserveAspectFit; smooth: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: infoRoot.sectionMode === "nso" ? tr("Nintendo Online") : tr("News")
                color: infoRoot.textMain
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.042 * fontScale)
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(12)

            // Lightweight TV Button right in News
            Rectangle {
                visible: infoRoot.sectionMode === "news"
                width: tvPillRow.implicitWidth + vpx(26); height: vpx(36); radius: vpx(18)
                color: infoRoot.focusZone === "tv" ? "#E60012" : "#111216"
                border.width: infoRoot.focusZone === "tv" ? vpx(3) : 1
                border.color: infoRoot.focusZone === "tv" ? "#FFFFFF" : "#38FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
                Row {
                    id: tvPillRow
                    anchors.centerIn: parent
                    spacing: vpx(8)
                    Item {
                        width: vpx(18); height: vpx(15)
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            width: vpx(8); height: vpx(2); color: "#FFFFFF"
                        }
                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: vpx(12); radius: vpx(2)
                            color: "transparent"; border.width: 2; border.color: "#FFFFFF"
                            Canvas {
                                anchors.centerIn: parent; width: vpx(6); height: vpx(6)
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                    ctx.moveTo(0, 0); ctx.lineTo(width, height / 2); ctx.lineTo(0, height);
                                    ctx.closePath(); ctx.fill();
                                }
                            }
                        }
                    }
                    Text {
                        text: tr("TV")
                        color: "#FFFFFF"
                        font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: infoRoot.openNewsTvMode(infoRoot.selectedIndex) }
            }

            Rectangle {
                visible: infoRoot.sectionMode === "news"
                width: locPillTxt.implicitWidth + vpx(24); height: vpx(34); radius: vpx(17)
                color: infoRoot.pillBg; border.width: 1; border.color: "#0284C7"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: locPillTxt
                    anchors.centerIn: parent
                    text: "Y · " + infoRoot.locationCountry
                    color: infoRoot.textMain
                    font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true
                }
                MouseArea { anchors.fill: parent; onClicked: infoRoot.openLocationPicker() }
            }
            Text {
                visible: infoRoot.isLoading
                text: tr("Updating live feed...")
                color: "#E60012"
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.022)
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "L / R · Category"
                color: infoRoot.textMuted
                font.family: titleFont.name
                font.pixelSize: Math.round(screenheight * 0.020)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: infoRoot.dividerColor }
    }

    // Horizontal Scrollable Category Bookmarks Bar (4-Way Controllable)
    Flickable {
        id: catFlick
        anchors { top: infoHeader.bottom; left: parent.left; right: parent.right; topMargin: vpx(10); leftMargin: screenmargin; rightMargin: screenmargin }
        height: vpx(46)
        clip: true
        contentWidth: catStrip.implicitWidth + vpx(16)
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds

        Row {
            id: catStrip
            height: parent.height
            spacing: vpx(10)

            Repeater {
                id: catRepeater
                model: infoRoot.activeCategories
                delegate: Rectangle {
                    property bool active: index === infoRoot.catIndex
                    property bool focusedCat: infoRoot.focusZone === "cats" && active
                    width: catTxt.implicitWidth + vpx(32); height: vpx(38); radius: vpx(19)
                    anchors.verticalCenter: parent.verticalCenter
                    color: active ? modelData.color : infoRoot.pillBg
                    border.width: focusedCat ? vpx(3.5) : (active ? 0 : 1)
                    border.color: focusedCat ? (infoRoot.isDarkPage ? "#FFFFFF" : "#111827") : infoRoot.dividerColor
                    scale: focusedCat ? 1.05 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120 } }

                    Text {
                        id: catTxt
                        anchors.centerIn: parent
                        text: modelData.label
                        color: parent.active ? "#FFFFFF" : infoRoot.textMain
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.022)
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            navSound.play();
                            infoRoot.focusZone = "cats";
                            infoRoot.loadCategory(index);
                        }
                    }
                }
            }
        }
    }

    // News Cards Grid (2x2)
    GridView {
        id: newsGrid
        anchors {
            top: catFlick.bottom; bottom: infoFooter.top; left: parent.left; right: parent.right
            topMargin: vpx(10); bottomMargin: vpx(10); leftMargin: screenmargin; rightMargin: screenmargin
        }
        clip: true
        cellWidth: Math.floor(width / infoRoot.gridColumns)
        cellHeight: Math.round(height / 2)
        model: feedModel
        currentIndex: infoRoot.selectedIndex

        delegate: Item {
            width: newsGrid.cellWidth
            height: newsGrid.cellHeight
            property bool selected: infoRoot.focusZone === "grid" && index === infoRoot.selectedIndex

            Rectangle {
                anchors { fill: parent; margins: vpx(8) }
                radius: vpx(14)
                color: infoRoot.cardBg
                clip: true
                scale: selected ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                // Top Image Area
                Item {
                    id: cardImgWrap
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: Math.round(parent.height * 0.48)

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: model.catColor || "#E60012" }
                            GradientStop { position: 1.0; color: "#111827" }
                        }
                        Image {
                            visible: cardImg.status !== Image.Ready
                            anchors.centerIn: parent
                            width: vpx(48); height: vpx(48)
                            source: infoRoot.sectionMode === "nso" ? "../assets/images/navigation/ns2_online.svg" : "../assets/images/navigation/ns2_news.svg"
                            fillMode: Image.PreserveAspectFit; opacity: 0.9
                        }
                    }

                    Image {
                        id: cardImg
                        property int retryStage: 0
                        anchors.fill: parent
                        source: model.image || model.fallbackImage || "../assets/images/blurbg.png"
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                        onStatusChanged: {
                            if (status === Image.Error) {
                                if (retryStage === 0 && model.image && String(model.image).indexOf("http") === 0 && String(model.image).indexOf("wsrv.nl") === -1) {
                                    retryStage = 1;
                                    source = "https://wsrv.nl/?url=" + encodeURIComponent(model.image) + "&output=jpg&w=800&n=-1";
                                } else if (retryStage <= 1) {
                                    retryStage = 2;
                                    source = model.fallbackImage || "../assets/images/blurbg.png";
                                } else if (retryStage === 2) {
                                    retryStage = 3;
                                    source = "../assets/images/blurbg.png";
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors { top: parent.top; left: parent.left; topMargin: vpx(8); leftMargin: vpx(8) }
                        width: srcBadge.implicitWidth + vpx(16); height: vpx(24); radius: vpx(6)
                        color: "#CC000000"
                        Text {
                            id: srcBadge
                            anchors.centerIn: parent
                            text: model.source + " · " + model.date
                            color: "#FFFFFF"
                            font.family: titleFont.name
                            font.pixelSize: vpx(12)
                            font.bold: true
                        }
                    }

                    Rectangle {
                        visible: !!model.hasVideo
                        anchors { top: parent.top; right: parent.right; topMargin: vpx(8); rightMargin: vpx(8) }
                        width: vpx(74); height: vpx(24); radius: vpx(6)
                        color: "#E60012"
                        Row {
                            anchors.centerIn: parent; spacing: vpx(5)
                            Canvas {
                                width: vpx(8); height: vpx(9); anchors.verticalCenter: parent.verticalCenter
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                    ctx.moveTo(0, 0); ctx.lineTo(width, height / 2); ctx.lineTo(0, height);
                                    ctx.closePath(); ctx.fill();
                                }
                            }
                            Text {
                                text: "VIDEO"
                                color: "#FFFFFF"
                                font.family: titleFont.name
                                font.pixelSize: vpx(11)
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                // Bigger Readable Card Title & Short NSO / News Summary Preview
                Column {
                    anchors {
                        top: cardImgWrap.bottom; bottom: parent.bottom; left: parent.left; right: parent.right
                        margins: vpx(12); topMargin: vpx(8)
                    }
                    spacing: vpx(4)

                    Text {
                        width: parent.width
                        text: model.title
                        color: infoRoot.textMain
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.036)
                        font.bold: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        lineHeight: 1.14
                    }
                    Text {
                        width: parent.width
                        text: infoRoot.shortNsoCardDesc(model.desc, infoRoot.sectionMode === "nso")
                        color: infoRoot.textMuted
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.020 * (infoRoot.sectionMode === "nso" ? 1.0 : Math.min(1.25, infoRoot.readerFontScale)))
                        wrapMode: Text.WordWrap
                        maximumLineCount: infoRoot.sectionMode === "nso" ? 1 : 2
                        elide: Text.ElideRight
                        lineHeight: 1.22
                    }
                }

                // Selection border in front
                Rectangle {
                    anchors.fill: parent
                    radius: vpx(14)
                    color: "transparent"
                    border.width: selected ? vpx(4) : 1
                    border.color: selected ? "#E60012" : infoRoot.dividerColor
                    z: 20
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        infoRoot.focusZone = "grid";
                        infoRoot.selectedIndex = index;
                        infoRoot.openArticleAt(index);
                    }
                }
            }
        }
    }

    Text {
        visible: !infoRoot.isLoading && feedModel.count === 0 && infoRoot.fetchError !== ""
        anchors.centerIn: newsGrid
        text: infoRoot.fetchError
        color: infoRoot.textMuted
        font.family: titleFont.name
        font.pixelSize: Math.round(screenheight * 0.024)
    }

    // Sticky Bottom Footer (Clean side-by-side explicit widths so X Refresh never pushes B offscreen)
    Item {
        id: infoFooter
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
        height: Math.round(screenheight * 0.095)
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: infoRoot.dividerColor }
        Image { anchors { left: parent.left; verticalCenter: parent.verticalCenter } width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true }

        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: vpx(18)

            Item {
                width: vpx(124); height: vpx(38); anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    anchors.fill: parent; radius: vpx(19)
                    color: infoRoot.pillBg; border.width: 1; border.color: infoRoot.dividerColor
                }
                Row {
                    anchors.centerIn: parent; spacing: vpx(8)
                    Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "X"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true }
                    }
                    Text { text: tr("Refresh"); color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: { navSound.play(); infoRoot.loadCategory(infoRoot.catIndex, true); } }
            }

            Item {
                width: vpx(90); height: vpx(38); anchors.verticalCenter: parent.verticalCenter
                Row {
                    anchors.centerIn: parent; spacing: vpx(8)
                    Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "A"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                    }
                    Text { text: tr("Read"); color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: infoRoot.openArticleAt(infoRoot.selectedIndex) }
            }

            Item {
                width: vpx(90); height: vpx(38); anchors.verticalCenter: parent.verticalCenter
                Row {
                    anchors.centerIn: parent; spacing: vpx(8)
                    Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "B"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                    }
                    Text { text: tr("Back"); color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: infoRoot.exitScreen() }
            }
        }
    }

    // FULLSCREEN ARTICLE READER OVERLAY
    FocusScope {
        id: readerOverlay
        anchors.fill: parent
        visible: infoRoot.readerOpen
        focus: infoRoot.readerOpen && !infoRoot.videoFullscreen
        z: 60

        Keys.onUpPressed: {
            readerFlick.contentY = Math.max(0, readerFlick.contentY - vpx(105));
        }
        Keys.onDownPressed: {
            var maxY = Math.max(0, readerFlick.contentHeight - readerFlick.height);
            readerFlick.contentY = Math.min(maxY, readerFlick.contentY + vpx(105));
        }
        Keys.onBackPressed: {
            event.accepted = true;
            if (infoRoot.videoFullscreen) infoRoot.closeNewsVideoFullscreen();
            infoRoot.readerOpen = false;
            infoRoot.focusZone = "grid";
            infoRoot.exitScreen();
        }
        Keys.onEscapePressed: {
            event.accepted = true;
            if (infoRoot.videoFullscreen) infoRoot.closeNewsVideoFullscreen();
            else infoRoot.closeReader();
        }
        Keys.onReleased: {
            if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
                root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
        }
        Keys.onPressed: {
            if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) {
                event.accepted = true;
                return;
            }
            if (infoRoot.videoFullscreen) return;
            if (infoRoot.isBackEvent(event) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.closeReader();
            } else if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.prevArticle();
            } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.nextArticle();
            } else if ((api.keys.isFilters(event) || api.keys.isDetails(event) || event.key === Qt.Key_X || event.key === Qt.Key_Y) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.cycleReaderTextSize();
            } else if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                event.accepted = true;
                if (infoRoot.activeArticle.hasVideo || infoRoot.readerVideoUrl !== "") {
                    infoRoot.openNewsVideoFullscreen();
                } else {
                    infoRoot.openExternalArticle();
                }
            }
        }

        Rectangle { anchors.fill: parent; color: infoRoot.pageBg }

        // Unified Scrollable Reader: Top Hero Photo + Headline + Paragraphs + Inline Small Photos Move Together
        Flickable {
            id: readerFlick
            anchors {
                top: parent.top; bottom: readerFooter.top; left: parent.left; right: parent.right
            }
            contentWidth: width
            contentHeight: readerStoryWrap.implicitHeight + vpx(28)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Behavior on contentY { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

            Column {
                id: readerStoryWrap
                width: readerFlick.width
                spacing: vpx(18)

                // Top Half Photo (46% height) inside the scroll view so it moves up seamlessly when scrolling text
                Item {
                    id: readerPhotoBox
                    width: parent.width
                    height: Math.round(readerOverlay.height * 0.46)
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: infoRoot.activeArticle.catColor || "#E60012" }
                            GradientStop { position: 1.0; color: "#111827" }
                        }
                        Image {
                            visible: readerHeroImg.status !== Image.Ready
                            anchors.centerIn: parent; width: vpx(72); height: vpx(72)
                            source: infoRoot.sectionMode === "nso" ? "../assets/images/navigation/ns2_online.svg" : "../assets/images/navigation/ns2_news.svg"
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Image {
                        id: readerHeroImg
                        property int retryStage: 0
                        anchors.fill: parent
                        source: infoRoot.readerFullImage || infoRoot.activeArticle.image || "../assets/images/blurbg.png"
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                        onStatusChanged: {
                            if (status === Image.Error) {
                                var curUrl = infoRoot.readerFullImage || infoRoot.activeArticle.image || "";
                                if (retryStage === 0 && curUrl.indexOf("http") === 0 && curUrl.indexOf("wsrv.nl") === -1) {
                                    retryStage = 1;
                                    source = "https://wsrv.nl/?url=" + encodeURIComponent(curUrl) + "&output=jpg&w=1000&n=-1";
                                } else if (retryStage <= 1) {
                                    retryStage = 2;
                                    source = "../assets/images/blurbg.png";
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#22000000" }
                            GradientStop { position: 0.65; color: "#11000000" }
                            GradientStop { position: 1.0; color: "#CC000000" }
                        }
                    }

                    Rectangle {
                        visible: !!(infoRoot.activeArticle.hasVideo || (infoRoot.readerVideoUrl && infoRoot.readerVideoUrl !== ""))
                        anchors.centerIn: parent
                        width: vpx(210); height: vpx(58); radius: height / 2
                        color: "#E6E60012"
                        border.width: vpx(2); border.color: "#FFFFFF"
                        z: 10
                        Row {
                            anchors.centerIn: parent; spacing: vpx(12)
                            Canvas {
                                width: vpx(16); height: vpx(18); anchors.verticalCenter: parent.verticalCenter
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                    ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                    ctx.moveTo(0, 0); ctx.lineTo(width, height / 2); ctx.lineTo(0, height);
                                    ctx.closePath(); ctx.fill();
                                }
                            }
                            Text { text: tr("Play Video"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.025 * fontScale); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }
                        MouseArea { anchors.fill: parent; onClicked: infoRoot.openNewsVideoFullscreen() }
                    }

                    Row {
                        anchors { left: parent.left; bottom: parent.bottom; leftMargin: screenmargin; bottomMargin: vpx(16) }
                        spacing: vpx(10)
                        Rectangle {
                            height: vpx(30); width: rBadgeTxt.implicitWidth + vpx(20); radius: vpx(15)
                            color: infoRoot.activeArticle.catColor || "#E60012"
                            Text { id: rBadgeTxt; anchors.centerIn: parent; text: infoRoot.activeArticle.source || "Nintendo"; color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: infoRoot.activeArticle.date || ""
                            color: "#E5E7EB"
                            font.family: titleFont.name
                            font.pixelSize: vpx(15)
                            font.bold: true
                        }
                    }
                }

                // Story Headline + Complete Paragraphs & Inline Small Photos
                Column {
                    id: readerStoryCol
                    width: parent.width - screenmargin * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(14)

                    Text {
                        width: parent.width
                        text: infoRoot.activeArticle.title || ""
                        color: infoRoot.textMain
                        font.family: titleFont.name
                        font.pixelSize: Math.round(screenheight * 0.040)
                        font.bold: true
                        wrapMode: Text.WordWrap
                        lineHeight: 1.2
                    }

                    Rectangle { width: parent.width; height: 1; color: infoRoot.dividerColor }

                    Repeater {
                        model: readerBlocksModel
                        delegate: Text {
                            width: readerStoryCol.width
                            text: model.text || ""
                            color: infoRoot.textMain
                            font.family: titleFont.name
                            font.pixelSize: Math.round(screenheight * 0.030 * infoRoot.readerFontScale * fontScale)
                            wrapMode: Text.WordWrap
                            lineHeight: 1.45
                        }
                    }
                }
            }
        }

        // Reader Bottom Controls
        Item {
            id: readerFooter
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: screenmargin; rightMargin: screenmargin }
            height: Math.round(screenheight * 0.105)
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: infoRoot.dividerColor }

            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: vpx(10)
                Image { width: vpx(36); height: vpx(26); source: "../assets/images/navigation/ns2_controller_glyph.svg"; fillMode: Image.PreserveAspectFit; smooth: true; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "LB / RB · Prev / Next Story"
                    color: infoRoot.textMuted
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight * 0.020)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: vpx(14)

                Item {
                    width: vpx(124); height: vpx(44); anchors.verticalCenter: parent.verticalCenter
                    Rectangle { anchors.fill: parent; radius: vpx(12); color: infoRoot.pillBg; border.width: 1; border.color: infoRoot.dividerColor }
                    Row {
                        anchors.centerIn: parent; spacing: vpx(8)
                        Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "X"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(13); font.bold: true }
                        }
                        Text { text: tr("Text ") + Math.round(infoRoot.readerFontScale * 100) + "%"; color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022 * fontScale); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: infoRoot.cycleReaderTextSize() }
                }

                Rectangle {
                    width: vpx(148); height: vpx(46); radius: vpx(12)
                    color: "#E60012"
                    anchors.verticalCenter: parent.verticalCenter
                    Row {
                        anchors.centerIn: parent; spacing: vpx(10)
                        Rectangle { width: vpx(24); height: vpx(24); radius: width / 2; color: "#FFFFFF"; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "A"; color: "#E60012"; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                        }
                        Text { text: tr("Open"); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.025); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: infoRoot.openExternalArticle() }
                }

                Item {
                    width: vpx(90); height: vpx(44); anchors.verticalCenter: parent.verticalCenter
                    Row {
                        anchors.centerIn: parent; spacing: vpx(8)
                        Rectangle { width: vpx(26); height: vpx(26); radius: width / 2; color: infoRoot.textMain; anchors.verticalCenter: parent.verticalCenter
                            Text { anchors.centerIn: parent; text: "B"; color: infoRoot.pageBg; font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true }
                        }
                        Text { text: tr("Back"); color: infoRoot.textMain; font.family: titleFont.name; font.pixelSize: Math.round(screenheight * 0.022); font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: infoRoot.closeReader() }
                }
            }
        }
    }

    // Fullscreen Video / Lightweight News TV Overlay (Direct Child of infoRoot so TV Works From Grid OR Reader)
    FocusScope {
        id: newsVideoOverlay
        visible: infoRoot.videoFullscreen
        focus: infoRoot.videoFullscreen
        anchors.fill: parent
        z: 180

        Keys.onReleased: {
            if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function")
                root.handleGlobalSleepCombo(event.key, false, event.isAutoRepeat);
            if (!event.isAutoRepeat) infoRoot.stopNewsCassetteScrub();
        }
        Keys.onPressed: {
            if (typeof root !== "undefined" && typeof root.handleGlobalSleepCombo === "function" && root.handleGlobalSleepCombo(event.key, true, event.isAutoRepeat)) {
                event.accepted = true;
                return;
            }
            infoRoot.bumpNewsPlayerOsd();
            if (infoRoot.isBackEvent(event) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.stopNewsCassetteScrub();
                infoRoot.closeNewsVideoFullscreen();
            } else if ((api.keys.isAccept(event) || event.key === Qt.Key_Space || event.key === Qt.Key_P) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.toggleNewsVideoPlayPause();
            } else if (event.key === Qt.Key_Left) {
                event.accepted = true;
                if (infoRoot.tvMode) {
                    if (!event.isAutoRepeat) infoRoot.stepTvVideo(-1);
                } else if (infoRoot.activeVideoStreamUrl !== "" && newsFullVideo.duration > 0) {
                    infoRoot.seekFluidlyTo((newsFullVideo.position || 0) - 8000);
                }
            } else if (event.key === Qt.Key_Right) {
                event.accepted = true;
                if (infoRoot.tvMode) {
                    if (!event.isAutoRepeat) infoRoot.stepTvVideo(1);
                } else if (infoRoot.activeVideoStreamUrl !== "" && newsFullVideo.duration > 0) {
                    infoRoot.seekFluidlyTo((newsFullVideo.position || 0) + 8000);
                }
            } else if ((api.keys.isPrevPage(event) || event.key === Qt.Key_BracketLeft) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.stepTvVideo(-1);
            } else if ((api.keys.isNextPage(event) || event.key === Qt.Key_BracketRight) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.stepTvVideo(1);
            } else if (event.key === Qt.Key_F9 || event.key === Qt.Key_MediaPrevious) {
                event.accepted = true;
                infoRoot.startNewsCassetteScrub(-1);
            } else if (event.key === Qt.Key_F10 || event.key === Qt.Key_MediaNext) {
                event.accepted = true;
                infoRoot.startNewsCassetteScrub(1);
            } else if ((api.keys.isDetails(event) || event.key === Qt.Key_Y) && !event.isAutoRepeat) {
                event.accepted = true;
                infoRoot.newsPlayerAspectMode = (infoRoot.newsPlayerAspectMode + 1) % 4;
            }
        }

        Rectangle { anchors.fill: parent; color: "#090B10" }

        // Ambient Artwork Surroundings (replaces plain black bars)
        Image {
            id: newsAmbientImg
            anchors.fill: parent
            source: infoRoot.readerFullImage || infoRoot.activeArticle.image || "../assets/images/blurbg.png"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        FastBlur {
            anchors.fill: parent
            source: newsAmbientImg
            radius: 44
            transparentBorder: false
            opacity: 0.65
        }
        Rectangle {
            anchors.fill: parent
            color: "#66090B10"
        }
        Rectangle {
            anchors { fill: parent; margins: vpx(12) }
            radius: vpx(14)
            color: "transparent"
            border.width: 1
            border.color: "#26FFFFFF"
        }

        Item {
            id: newsVideoHost
            anchors.centerIn: parent
            width: infoRoot.newsPlayerAspectMode === 2 ? Math.min(parent.width, parent.height)
                 : infoRoot.newsPlayerAspectMode === 1 ? Math.min(parent.width, Math.round(parent.height * 16 / 9))
                 : parent.width
            height: infoRoot.newsPlayerAspectMode === 2 ? Math.min(parent.width, parent.height)
                  : infoRoot.newsPlayerAspectMode === 1 ? Math.min(parent.height, Math.round(parent.width * 9 / 16))
                  : parent.height
            clip: true
            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Video {
                id: newsFullVideo
                anchors.fill: parent
                source: infoRoot.activeVideoStreamUrl
                fillMode: (infoRoot.newsPlayerAspectMode === 3 || infoRoot.newsPlayerAspectMode === 2) ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit
                autoPlay: true
                muted: false
                volume: 1.0
                visible: infoRoot.activeVideoStreamUrl !== ""
                onStatusChanged: {
                    if ((status === MediaPlayer.Loaded || status === MediaPlayer.Buffered) && !infoRoot.newsPlayerPaused && playbackState !== MediaPlayer.PlayingState) {
                        play();
                    } else if (status === MediaPlayer.InvalidMedia && infoRoot.videoFullscreen) {
                        infoRoot.resolveSteamNewsFallback(infoRoot.activeVideoTitle || "Nintendo Switch 2", infoRoot.videoReqCounter);
                    } else if (status === MediaPlayer.EndOfMedia && infoRoot.tvMode) {
                        infoRoot.stepTvVideo(1);
                    }
                }
                onErrorChanged: {
                    if (error !== MediaPlayer.NoError && infoRoot.videoFullscreen && infoRoot.activeVideoStreamUrl !== "") {
                        infoRoot.resolveDailymotionById("x9cgvkm", infoRoot.videoReqCounter);
                    }
                }
            }
        }

        // Loading Badge while resolving stream
        Rectangle {
            visible: infoRoot.videoLoading
            anchors.centerIn: parent
            width: loadTxt.implicitWidth + vpx(44); height: vpx(46); radius: vpx(23)
            color: "#CC0B0C10"; border.width: 1; border.color: "#38FFFFFF"
            Text {
                id: loadTxt
                anchors.centerIn: parent
                text: tr("Starting News Video...")
                color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(16); font.bold: true
            }
        }

        // Lightweight TV Channel Title Pill (auto-hides with OSD)
        Rectangle {
            visible: (infoRoot.newsPlayerOsdVisible || infoRoot.tvMode) && infoRoot.activeVideoTitle !== ""
            opacity: (infoRoot.newsPlayerOsdVisible || infoRoot.newsPlayerPaused || infoRoot.scrubDir !== 0) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220 } }
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: vpx(24) }
            height: vpx(48); radius: vpx(12)
            color: "#CC0A0B0F"; border.width: 1; border.color: "#24FFFFFF"
            Row {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: vpx(16); rightMargin: vpx(16) }
                spacing: vpx(12)
                Rectangle {
                    visible: infoRoot.tvMode
                    width: chTxt.implicitWidth + vpx(18); height: vpx(26); radius: vpx(6)
                    color: "#E60012"
                    anchors.verticalCenter: parent.verticalCenter
                    Text { id: chTxt; anchors.centerIn: parent; text: "TV " + (infoRoot.tvIndex + 1) + "/" + Math.max(1, feedModel.count); color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(12); font.bold: true }
                }
                Text {
                    width: parent.width - (infoRoot.tvMode ? vpx(110) : vpx(20))
                    text: infoRoot.activeVideoTitle
                    color: "#FFFFFF"; font.family: titleFont.name; font.pixelSize: vpx(15); font.bold: true
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: infoRoot.bumpNewsPlayerOsd()
        }

        // Big Flat Nintendo Black Lower-Third Media Player Controls (Pure Vector Shapes - Zero Missing Unicode Symbols!)
        Rectangle {
            id: newsPlayerLowerThird
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(148)
            color: "#EB08090D"
            border.width: 1
            border.color: "#22FFFFFF"
            opacity: (infoRoot.newsPlayerOsdVisible || infoRoot.newsPlayerPaused || infoRoot.scrubDir !== 0) ? 1.0 : 0.0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 220 } }

            Column {
                anchors { fill: parent; leftMargin: vpx(28); rightMargin: vpx(28); topMargin: vpx(14); bottomMargin: vpx(14) }
                spacing: vpx(14)

                // Row 1: Fluid Click & Drag Scrubber + Start - End Time
                Row {
                    width: parent.width
                    height: vpx(26)
                    spacing: vpx(12)

                    Text {
                        width: vpx(58)
                        anchors.verticalCenter: parent.verticalCenter
                        text: infoRoot.formatVideoMs(newsFullVideo.position)
                        color: "#FFFFFF"
                        font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true
                    }
                    Rectangle {
                        id: newsScrubTrack
                        width: parent.width - vpx(140); height: vpx(10); radius: vpx(5)
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#3CFFFFFF"
                        Rectangle {
                            height: parent.height; radius: vpx(5); color: "#E60012"
                            width: (newsFullVideo.duration > 0)
                                ? Math.max(vpx(10), Math.min(parent.width, parent.width * (newsFullVideo.position / newsFullVideo.duration)))
                                : 0
                        }
                        MouseArea {
                            anchors { fill: parent; topMargin: -vpx(14); bottomMargin: -vpx(14) }
                            onPressed: {
                                if (newsFullVideo.duration > 0) infoRoot.seekFluidlyTo((mouse.x / width) * newsFullVideo.duration);
                            }
                            onPositionChanged: {
                                if (pressed && newsFullVideo.duration > 0) {
                                    var r = Math.max(0, Math.min(1, mouse.x / width));
                                    infoRoot.seekFluidlyTo(r * newsFullVideo.duration);
                                }
                            }
                        }
                    }
                    Text {
                        width: vpx(58)
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                        text: infoRoot.formatVideoMs(newsFullVideo.duration)
                        color: "#A1A1AA"
                        font.family: titleFont.name; font.pixelSize: vpx(14); font.bold: true
                    }
                }

                // Row 2: Way Bigger Flat Nintendo Black Media Buttons (Vector Icons Only)
                Item {
                    width: parent.width
                    height: vpx(72)

                    Row {
                        anchors.centerIn: parent
                        spacing: vpx(16)

                        // Prev News Video (L1)
                        Rectangle {
                            width: vpx(76); height: vpx(58); radius: vpx(12)
                            color: "#15171E"; border.width: 2; border.color: "#38FFFFFF"
                            Row {
                                anchors.centerIn: parent; spacing: vpx(3)
                                Rectangle { width: vpx(4); height: vpx(18); radius: vpx(1); color: "#FFFFFF" }
                                Canvas {
                                    width: vpx(14); height: vpx(18)
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                        ctx.moveTo(width, 0); ctx.lineTo(0, height / 2); ctx.lineTo(width, height);
                                        ctx.closePath(); ctx.fill();
                                    }
                                }
                            }
                            MouseArea { anchors.fill: parent; onClicked: infoRoot.stepTvVideo(-1) }
                        }

                        // Rewind (Fluid Hold)
                        Rectangle {
                            width: vpx(82); height: vpx(58); radius: vpx(12)
                            color: infoRoot.scrubDir < 0 ? "#2A2E3B" : "#15171E"
                            border.width: 2; border.color: infoRoot.scrubDir < 0 ? "#FFFFFF" : "#38FFFFFF"
                            Row {
                                anchors.centerIn: parent; spacing: vpx(2)
                                Canvas {
                                    width: vpx(12); height: vpx(16)
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                        ctx.moveTo(width, 0); ctx.lineTo(0, height / 2); ctx.lineTo(width, height);
                                        ctx.closePath(); ctx.fill();
                                    }
                                }
                                Canvas {
                                    width: vpx(12); height: vpx(16)
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                        ctx.moveTo(width, 0); ctx.lineTo(0, height / 2); ctx.lineTo(width, height);
                                        ctx.closePath(); ctx.fill();
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: infoRoot.startNewsCassetteScrub(-1)
                                onReleased: infoRoot.stopNewsCassetteScrub()
                                onCanceled: infoRoot.stopNewsCassetteScrub()
                            }
                        }

                        // Big Central Flat Nintendo Black Play / Pause
                        Rectangle {
                            width: vpx(110); height: vpx(64); radius: vpx(14)
                            color: "#111216"; border.width: vpx(2.5); border.color: "#FFFFFF"
                            Item {
                                anchors.centerIn: parent
                                width: vpx(24); height: vpx(24)
                                Row {
                                    visible: !infoRoot.newsPlayerPaused && newsFullVideo.playbackState === MediaPlayer.PlayingState
                                    anchors.centerIn: parent
                                    spacing: vpx(6)
                                    Rectangle { width: vpx(6); height: vpx(22); radius: vpx(2); color: "#FFFFFF" }
                                    Rectangle { width: vpx(6); height: vpx(22); radius: vpx(2); color: "#FFFFFF" }
                                }
                                Canvas {
                                    visible: infoRoot.newsPlayerPaused || newsFullVideo.playbackState !== MediaPlayer.PlayingState
                                    anchors.centerIn: parent
                                    width: vpx(20); height: vpx(22)
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                        ctx.moveTo(0, 0); ctx.lineTo(width, height / 2); ctx.lineTo(0, height);
                                        ctx.closePath(); ctx.fill();
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: infoRoot.toggleNewsVideoPlayPause()
                            }
                        }

                        // Fast Forward (Fluid Hold)
                        Rectangle {
                            width: vpx(82); height: vpx(58); radius: vpx(12)
                            color: infoRoot.scrubDir > 0 ? "#2A2E3B" : "#15171E"
                            border.width: 2; border.color: infoRoot.scrubDir > 0 ? "#FFFFFF" : "#38FFFFFF"
                            Row {
                                anchors.centerIn: parent; spacing: vpx(2)
                                Canvas {
                                    width: vpx(12); height: vpx(16)
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                        ctx.moveTo(0, 0); ctx.lineTo(width, height / 2); ctx.lineTo(0, height);
                                        ctx.closePath(); ctx.fill();
                                    }
                                }
                                Canvas {
                                    width: vpx(12); height: vpx(16)
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                        ctx.moveTo(0, 0); ctx.lineTo(width, height / 2); ctx.lineTo(0, height);
                                        ctx.closePath(); ctx.fill();
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: infoRoot.startNewsCassetteScrub(1)
                                onReleased: infoRoot.stopNewsCassetteScrub()
                                onCanceled: infoRoot.stopNewsCassetteScrub()
                            }
                        }

                        // Next News Video (R1)
                        Rectangle {
                            width: vpx(76); height: vpx(58); radius: vpx(12)
                            color: "#15171E"; border.width: 2; border.color: "#38FFFFFF"
                            Row {
                                anchors.centerIn: parent; spacing: vpx(3)
                                Canvas {
                                    width: vpx(14); height: vpx(18)
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                        ctx.fillStyle = "#FFFFFF"; ctx.beginPath();
                                        ctx.moveTo(0, 0); ctx.lineTo(width, height / 2); ctx.lineTo(0, height);
                                        ctx.closePath(); ctx.fill();
                                    }
                                }
                                Rectangle { width: vpx(4); height: vpx(18); radius: vpx(1); color: "#FFFFFF" }
                            }
                            MouseArea { anchors.fill: parent; onClicked: infoRoot.stepTvVideo(1) }
                        }
                    }

                    // Single In-Place Aspect Ratio Icon (Zero Text)
                    Rectangle {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        width: vpx(68); height: vpx(58); radius: vpx(12)
                        color: "#15171E"; border.width: 2; border.color: "#38FFFFFF"
                        Rectangle {
                            anchors.centerIn: parent
                            width: infoRoot.newsPlayerAspectMode === 2 ? vpx(18) : infoRoot.newsPlayerAspectMode === 1 ? vpx(28) : vpx(22)
                            height: infoRoot.newsPlayerAspectMode === 2 ? vpx(18) : infoRoot.newsPlayerAspectMode === 1 ? vpx(16) : vpx(17)
                            radius: vpx(3)
                            color: infoRoot.newsPlayerAspectMode === 3 ? "#88FFFFFF" : "transparent"
                            border.width: 2; border.color: "#FFFFFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                infoRoot.newsPlayerAspectMode = (infoRoot.newsPlayerAspectMode + 1) % 4;
                                infoRoot.bumpNewsPlayerOsd();
                            }
                        }
                    }
                }
            }
        }
    }
}

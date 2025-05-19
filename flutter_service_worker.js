'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "1acebcc4ea015b6a13c309a31229db11",
"assets/AssetManifest.bin.json": "1b26c397db9945a88db12ea966546892",
"assets/AssetManifest.json": "a75f11c1d63e0f31b72c621fdba1e0d6",
"assets/assets/images/1.jpg": "395ea245957c6821cf6d823fd3651741",
"assets/assets/images/2.jpg": "9195bc0f46512cafbdfba2d5612d9897",
"assets/assets/images/3.jpg": "c4d983666d3bffacffbe6a78b435c0ce",
"assets/assets/images/4.jpg": "d886d0fb47916932e418be378f4bd1b7",
"assets/assets/images/5.jpg": "4e09a68cc8d867df0c13c1101fc32abc",
"assets/assets/images/banner1.jpg": "39a50609eb7687c5364b65f6b81da213",
"assets/assets/images/banner2.jpg": "7d20f9c4b2a83678fc4f5ad4305f37a5",
"assets/assets/images/banner3.png": "59003b2ab092c7fdead679e42cf9979d",
"assets/assets/images/bn1.jpg": "0676a2acde76c0d3129cfe3ed323b197",
"assets/assets/images/bn2.jpg": "faba33a0c4f4170a4d9457e0e02bf8eb",
"assets/assets/images/bn3.jpg": "e0a53db2072261f99ffde5be73c8147c",
"assets/assets/images/cd1.jpg": "db2dab5cf084d95f38fc411059bea350",
"assets/assets/images/cd2.jpg": "bb9331e9dc83e813bd3326a910af660f",
"assets/assets/images/headphones.jpg": "65c8951adec96ec281ad08e5ac5ca88f",
"assets/assets/images/laptop.jpg": "4417c0245d5a3cd6efbb8a6bc78e4f7c",
"assets/assets/images/logo.png": "578fd080e7dd9964a3e98bc5c0cdd51b",
"assets/assets/images/logoapbar.jpg": "2ed2ca4e148e7db666cf0519c9fc0f59",
"assets/assets/images/macbook_main.jpg": "e24334df75944340d6327512d57aa21d",
"assets/assets/images/macbook_thumb1.jpg": "2efddeb5306bbc0307044960ce14a2a5",
"assets/assets/images/macbook_thumb2.jpg": "001e5bea9e8ba3db728e9440359d4938",
"assets/assets/images/voucher1.jpg": "7314f86b6cc61e5c2a65d40d3af5c322",
"assets/assets/images/voucher2.jpg": "572ff9f0ba4c1f25fab6c92aae74dc7a",
"assets/assets/Logo.png": "aa77c36d6f960bccf3219bf387af876f",
"assets/assets/Manager/Avatar/avatar.jpg": "09c6ef9f8d66432c1b1a4eeb94b96956",
"assets/assets/Manager/Avatar/avatar01.jpg": "1f8af4402f703a6f64f3130b3ff1d71e",
"assets/assets/Manager/Avatar/avatar02.jpg": "de03af7317c344b57514cbcfb1d26eb9",
"assets/assets/Manager/Avatar/avatar03.jpg": "3f74e529c5081b0314647f702a7f8f19",
"assets/assets/Manager/Avatar/avatar04.jpg": "db72b26707bb3c0dce226f9895f1f0eb",
"assets/assets/Manager/Avatar/avatar05.jpg": "c04a67e70ca5f597a734816052ce9379",
"assets/assets/Manager/Coupon/coupon1.jpg": "a4eca1525e3b0ab72b7cf60d1e0a38ed",
"assets/assets/placeholder.jpg": "ce3bcd014de235f655703e2a3a2b3eca",
"assets/FontManifest.json": "4fb15aa4f8d54928480644fdce53de45",
"assets/fonts/MaterialIcons-Regular.otf": "88b1ae4ad83f3d33f202349bac4061e6",
"assets/NOTICES": "df3a8906ac98ea3f14f223e5497f6b98",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "4769f3245a24c1fa9965f113ea85ec2a",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "3ca5dc7621921b901d513cc1ce23788c",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "fd74642700244c27c5150534099b9dd6",
"assets/packages/lucide_icons/assets/lucide.ttf": "f9ba0b4172a0beabfecd5857b55dfe72",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"flutter_bootstrap.js": "26c8e89c57c4b360e559e131fc43a37e",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "763d69224cde6f81ca21b5a967e10cf9",
"/": "763d69224cde6f81ca21b5a967e10cf9",
"main.dart.js": "4011098ff814cd98e6007b174dc1956c",
"manifest.json": "1dd3108520883b80e79e0d3ef3edc7c0",
"version.json": "6eee1bd6687b80b56d01ba4fcdafb0d6"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

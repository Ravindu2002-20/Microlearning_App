import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async () => {
  const YOUTUBE_API_KEY = "AIzaSyDGBkp8Emjv-p-C3IXuWIoIo6ooHlJnlHY";

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

const searchRes = await fetch(searchUrl);
const searchData = await searchRes.json();

console.log("SEARCH DATA:");
console.log(JSON.stringify(searchData, null, 2));

if (!searchData.items) {
  return new Response(
    JSON.stringify({
      error: "YouTube API did not return items",
      response: searchData,
    }),
    {
      status: 500,
      headers: { "Content-Type": "application/json" },
    }
  );
}

const videoIds = searchData.items
  .map((i: any) => i.id.videoId)
  .join(",");

  const searchUrl =
    `https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=10&q=education&key=${YOUTUBE_API_KEY}`;

  const searchRes = await fetch(searchUrl);
  const searchData = await searchRes.json();

  console.log(JSON.stringify(searchData));

  const videoIds = searchData.items.map((i: any) => i.id.videoId).join(",");

  const videoUrl =
    `https://www.googleapis.com/youtube/v3/videos?part=contentDetails,snippet&id=${videoIds}&key=${YOUTUBE_API_KEY}`;

  const videoRes = await fetch(videoUrl);
  const videoData = await videoRes.json();

  const filtered = videoData.items.filter((v: any) => {
    const duration = v.contentDetails.duration;

    // simple check: under 60 seconds (basic version)
    return duration.includes("M") === false;
  });

  for (const v of filtered) {
    await supabase.from("videos").insert({
      youtube_video_id: v.id,
      title: v.snippet.title,
      description: v.snippet.description,
      thumbnail: v.snippet.thumbnails.high.url,
    });
  }

  return new Response(JSON.stringify(filtered), {
    headers: { "Content-Type": "application/json" },
  });
});
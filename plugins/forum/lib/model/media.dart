/// 类型
enum MediaType { image, video, voice }

/// 媒体对象
mixin Media {
  MediaType get type;
}

class ImageMedia with Media {
  ImageMedia(this.thumbUrl, this.url, this.width, this.height);

  @override
  MediaType get type => MediaType.image;
  final String thumbUrl;
  final String url;
  final int width;
  final int height;
}

class VideoMedia with Media {
  VideoMedia(this.coverUrl, this.url);

  @override
  MediaType get type => MediaType.video;
  final String coverUrl;
  final String url;
}

class VoiceMedia with Media {
  VoiceMedia(this.url);

  @override
  MediaType get type => MediaType.voice;
  final String url;
}

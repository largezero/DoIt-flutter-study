class TourData {
  String? title;
  String? tel;
  String? zipcode;
  String? address;
  var id;
  var mapx;
  var mapy;
  String? imagePath;

  TourData({
    this.id, this.title, this.tel, this.zipcode, this.address, this.mapx, this.mapy, this.imagePath
  });

  TourData.fromJson(Map data)
      : id = data['contentid'],
        title = data['title'],
        tel = data['tel'],
        zipcode = data['zipcode'],
        // address = data['address'],
        address = data['addr1'] + (data['addr2'] ?? ''),
        mapx = data['mapx'],
        mapy = data['mapy'],
        imagePath = data['firstimage'];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'tel': title,
      'zipcode': zipcode,
      'address': address,
      'mapx': mapx,
      'mapy': mapy,
      'imagePath': imagePath,
    };
  }
}
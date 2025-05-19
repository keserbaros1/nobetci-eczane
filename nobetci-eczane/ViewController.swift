import UIKit
import CoreLocation
import Foundation

class ViewController: UIViewController,
                      UITableViewDelegate,
                      UITableViewDataSource,
                      CLLocationManagerDelegate {

    // Konum kısmı

    let locationManager = CLLocationManager()
    
    let apiKey = APIKeys.eczaneAPIKey

    @IBOutlet weak var konumBilgisiLabel: UILabel!

    // Şehir ve ilçe bilgilerini saklayacak değişkenler
    var il: String?
    var ilce: String?
    var currentUserLocation: CLLocation? // Kullanıcının mevcut konumu
    
    var eczaneler: [Eczane] = []


    @IBOutlet weak var TableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // Konum izni iste
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // Konum güncellendiğinde çalışır
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }


        // Konum bilgilerini sakla
        self.currentUserLocation = location 


        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude


        print("Enlem: \(latitude), Boylam: \(longitude)")

        // Adres düzenleme
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                self.il = placemark.administrativeArea ?? "Bilinmiyor"
                
            
                // ilçe bilgisini düzenlendiği kısım
                if let rawIlceName = placemark.subAdministrativeArea, !rawIlceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let components = rawIlceName.split(separator: " ").map(String.init)
                    
                    
                    // En sondaki bileşen ilçe adı oluyor. Onu alıyoruz.
                    if let districtName = components.last {
                        self.ilce = districtName
                        print("Tespit edilen ham ilçe: '\(rawIlceName)'. API için ayarlandı: '\(districtName)'")
                    } else {
                        self.ilce = rawIlceName.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("Tespit edilen ham ilçe: '\(rawIlceName)'. Son kelime ayrıştırılamadı, '\(self.ilce!)' olarak kullanılıyor.")
                    }
                } else {
                    self.ilce = "Bilinmiyor"
                    print("İlçe bilgisi (subAdministrativeArea) gelmedi veya boş.")
                }
                
                // Belki lazım olur                
                let mahalle = placemark.subLocality ?? "Bilinmiyor"

                
                print("İl: \(self.il ?? "Bilinmiyor"), İlçe: \(self.ilce ?? "Bilinmiyor"), Mahalle: \(mahalle)")

                // Label'ı ana iş parçacığında güncelle
                DispatchQueue.main.async {
                    self.konumBilgisiLabel.text = "\(self.ilce ?? "Bilinmiyor"), \(self.il ?? "Bilinmiyor")"
                    
                    // API isteğini sadece geçerli il ve ilçe bilgisi varsa yap
                    if let ilToFetch = self.il, ilToFetch != "Bilinmiyor",
                       let ilceToFetch = self.ilce, ilceToFetch != "Bilinmiyor" {
                        self.fetchEczaneler(il: ilToFetch, ilce: ilceToFetch)
                    } else {
                        print("İl veya İlçe bilgisi 'Bilinmiyor' olduğu için API isteği yapılmayacak.")
                        self.eczaneler = [] // Eczane listesini temizle
                        self.TableView.reloadData() // TableView'ı güncelle
                    }
                }
            } else if let error = error {
                print("Adres çözümleme hatası: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.konumBilgisiLabel.text = "Adres bulunamadı."
                }
            }

        }

        // Bir kez almak yeterli. durduruldu:
        locationManager.stopUpdatingLocation()
    }

    // Hata durumunda
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Konum alınamadı: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.konumBilgisiLabel.text = "Konum bilgisi alınamadı"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eczaneler.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(
                withIdentifier: "TableViewCell",
                for: indexPath)
        
        
        let eczane = eczaneler[indexPath.row]
        

        if let eczaneIsmiLabel = cell.viewWithTag(1) as? UILabel,
           let adresLabel = cell.viewWithTag(2) as? UILabel,
           let uzaklikLabel = cell.viewWithTag(3) as? UILabel {
            
            
            eczaneIsmiLabel.text = eczane.name
            adresLabel.text = eczane.address
            

            // Uzaklık hesaplama
            if let userLoc = currentUserLocation, !eczane.loc.isEmpty {
                let pharmacyLocString = eczane.loc
                let coordinates = pharmacyLocString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                if coordinates.count == 2, let lat = Double(coordinates[0]), let lon = Double(coordinates[1]) {
                    let pharmacyLocation = CLLocation(latitude: lat, longitude: lon)
                    let distanceInMeters = userLoc.distance(from: pharmacyLocation)
                    
                    if distanceInMeters < 1000 {
                        uzaklikLabel.text = String(format: "%.0f m", distanceInMeters)
                    } else {
                        uzaklikLabel.text = String(format: "%.1f km", distanceInMeters / 1000)
                    }
                } else {
                    uzaklikLabel.text = "--" // Geçersiz koordinat formatı
                }
            } else {
                uzaklikLabel.text = "?" // Konum bilgisi yok
            }
            uzaklikLabel.numberOfLines = 0

        
        }

        return cell

    }

/*
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedEczane = eczaneler[indexPath.row]
        
        // Storyboard'dan EczaneDetailPopupViewController'ı yükle
        // "EczaneDetailPopupVC" ID'sinin Storyboard'da doğru ayarlandığından emin olun.
        if let popupVC = storyboard?.instantiateViewController(withIdentifier: "EczaneDetailPopupVC") as? EczaneDetailPopupViewController {
            popupVC.eczane = selectedEczane
            popupVC.modalPresentationStyle = .overCurrentContext 
            popupVC.modalTransitionStyle = .crossDissolve
            
            present(popupVC, animated: true, completion: nil)
        }
    }
 */
    // override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //     if segue.identifier == "showDetailSegue" {
    //         if let destinationVC = segue.destination as? EczaneDetailPopupViewController,
    //         let selectedIndex = TableView.indexPathForSelectedRow?.row {
    //             // Seçilen eczaneyi ikinci sayfaya gönder
    //             destinationVC.eczane = eczaneler[selectedIndex]
    //         }
    //     }
    // }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    print("prepare for segue çağrıldı. Identifier: \(segue.identifier ?? "nil")")
    if segue.identifier == "showDetailSegue" {
        print("Segue identifier 'showDetailSegue' ile eşleşti.")
        if let selectedIndexPath = TableView.indexPathForSelectedRow {
            print("Seçili satırın indexPath'i: \(selectedIndexPath)")
            let selectedEczane = eczaneler[selectedIndexPath.row]
            print("Seçilen Eczane Bilgileri: \(selectedEczane)") // Seçilen eczanenin tüm detaylarını yazdır

            if let destinationVC = segue.destination as? EczaneDetailPopupViewController {
                print("Hedef VC EczaneDetailPopupViewController olarak cast edildi.")
                destinationVC.eczane = selectedEczane
                print("Eczane verisi hedef VC'ye atandı.")
            } else {
                print("Hata: Hedef VC EczaneDetailPopupViewController'a cast edilemedi. Gerçek tip: \(type(of: segue.destination))")
            }
        } else {
            print("Hata: TableView.indexPathForSelectedRow nil döndü.")
        }
    } else {
        print("Uyarı: Segue identifier 'showDetailSegue' ile eşleşmedi.")
    }
}

    
    
    
    
    // Api'den veri çekme kısmı
    
    func fetchEczaneler(il: String, ilce: String) {
        let headers = [
            "content-type": "application/json",
            "authorization": "apikey \(apiKey)"
        ]

        // Türkçe karakterleri URL'ye uygun hale getir
        let ilEncoded = il.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? il
        let ilceEncoded = ilce.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ilce

        let urlString = "https://api.collectapi.com/health/dutyPharmacy?ilce=\(ilceEncoded)&il=\(ilEncoded)"
        
        // Hangi il ve ilçe ile istek yapıldığını kontrol et
        print("API İsteği Yapılıyor: İl='\(il)', İlçe='\(ilce)'")
        print("Oluşturulan URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("Geçersiz URL oluşturuldu.")
            
            DispatchQueue.main.async {
                self.konumBilgisiLabel.text = "API isteği için geçersiz URL."
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            
            
            // 1. Ağ hatasını kontrol kısmı
            if let error = error {
                print("Ağ hatası oluştu: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    
                }
                return
            }


            // 2. HTTP yanıtını kontrol kısmı
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Durum Kodu: \(httpResponse.statusCode)")
                
            }

            // 3. Gelen veriyi kontrol etme kısmı
            guard let data = data else {
                print("API'den veri alınamadı.")
                return
            }

            // 4. HAM VERİYİ STRING OLARAK YAZDIR (ÇOK ÖNEMLİ SİLME. DEVRE DIŞI BIRAKIRSIN)
            if let rawResponseString = String(data: data, encoding: .utf8) {
                print("API'den Gelen Ham Yanıt: \(rawResponseString)")
            } else {
                print("Gelen veri UTF-8 string'e dönüştürülemedi.")
            }


            do {
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(ApiResponse.self, from: data)

                if apiResponse.success {
                    
                    self.eczaneler = apiResponse.result
                    
                    
                    DispatchQueue.main.async {
                        self.TableView.reloadData()
                        if self.eczaneler.isEmpty && !apiResponse.success {
                            
                            print("API yanıtı başarılı ancak bu bölgede nöbetçi eczane bulunamadı veya liste boş geldi.")
                        }
                        
                    }
                }   else {
                    print("API başarısız yanıt verdi (success: false).")

                    self.eczaneler = []
                    DispatchQueue.main.async {
                        self.TableView.reloadData() // Boş listeyi göstermek için
                    }
                }
            
            } catch let decodingError as DecodingError {
                print("JSON decode hatası oluştu: \(decodingError)")
                
                
                
                // Daha detaylı hata bilgisi kısmı:
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("--- Key '\(key)' not found at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    print("--- Debug Description: \(context.debugDescription)")
                
                case .dataCorrupted(let context):
                    print("--- Data corrupted: \(context.debugDescription)")
                
                case .typeMismatch(let type, let context):
                    print("--- Type '\(type)' mismatch: \(context.debugDescription) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                
                case .valueNotFound(let value, let context):
                    print("--- Value '\(value)' not found: \(context.debugDescription) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                
                @unknown default:
                    print("Bilinmeyen bir decode hatası.")
                }
            
            } catch {
                print("Beklenmedik bir hata oluştu: \(error)")
            
            }
        }

        task.resume()
    }

    
}


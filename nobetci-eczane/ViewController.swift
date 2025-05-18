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

    // Arayüzdeki Label'ı temsil eden IBOutlet
    @IBOutlet weak var konumBilgisiLabel: UILabel!

    // Şehir ve ilçe bilgilerini saklayacak değişkenler
    var il: String?
    var ilce: String?
    
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

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        print("Enlem: \(latitude), Boylam: \(longitude)")

        // Adres çözümleme (şehir, ilçe vs.)
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                self.il = placemark.administrativeArea ?? "Bilinmiyor"
                self.ilce = placemark.subAdministrativeArea ?? "Bilinmiyor"
                let mahalle = placemark.subLocality ?? "Bilinmiyor"

                print("İl: \(self.il ?? "Bilinmiyor"), İlçe: \(self.ilce ?? "Bilinmiyor"), Mahalle: \(mahalle)")

                // Label'ı ana iş parçacığında güncelle
                DispatchQueue.main.async {
                    self.konumBilgisiLabel.text = "\(self.ilce ?? "Bilinmiyor"), \(self.il ?? "Bilinmiyor")"
                    
                    if let il = self.il, let ilce = self.ilce {
                        self.fetchEczaneler(il: il, ilce: ilce)
                    }
                }
                
            }
        }

        // Bir kez almak yeterliyse durdur:
        locationManager.stopUpdatingLocation()
    }

    // Hata durumunda
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Konum alınamadı: \(error.localizedDescription)")
        // Hata durumunda label'ı güncelleyebilirsiniz:
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
        
        // Label'lara erişmek için tag kullanabilir ya da IBOutlet bağlayabilirsin
        if let eczaneIsmiLabel = cell.viewWithTag(1) as? UILabel,
           let adresLabel = cell.viewWithTag(2) as? UILabel,
           let uzaklikLabel = cell.viewWithTag(3) as? UILabel {
            eczaneIsmiLabel.text = eczane.name
            adresLabel.text = eczane.address
            uzaklikLabel.text = "" // Mesafeyi hesaplıyorsan buraya ekle
        }

        return cell

    }
    
    
    
    // Api'den veri çekme kısmı
    
    func fetchEczaneler(il: String, ilce: String) {
        let headers = [
            "content-type": "application/json",
            "authorization": "apikey \(apiKey)" // Buraya kendi token'ını yaz
        ]
        
        // Türkçe karakterleri URL'ye uygun hale getir
        let ilEncoded = il.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? il
        let ilceEncoded = ilce.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ilce

        let urlString = "https://api.collectapi.com/health/dutyPharmacy?ilce=\(ilceEncoded)&il=\(ilEncoded)"
        
        
        
        // Hangi il ve ilçe ile istek yapıldığını kontrol et
        print("API İsteği Yapılıyor: İl='\(ilceEncoded)', İlçe='\(ilEncoded)'")
        print("Oluşturulan URL: \(urlString)")
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Hata oluştu: \(error)")
                return
            }

            guard let data = data else { return }
            
            
            
            // 4. HAM VERİYİ STRING OLARAK YAZDIR
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
                    }
                }
            } catch {
                print("JSON decode hatası: \(error)")
            }
        }

        task.resume()
    }

    
}


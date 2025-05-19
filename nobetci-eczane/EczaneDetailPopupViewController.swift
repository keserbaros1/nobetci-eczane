//
//  EczaneDetailPopupViewController.swift
//  nobetci-eczane
//
//  Created by kesermac on 19.05.2025.
//

import UIKit
import MapKit

class EczaneDetailPopupViewController: UIViewController {

    var eczane: Eczane?

    @IBOutlet weak var containerView: UIView! 
    @IBOutlet weak var eczaneAdiLabel: UILabel!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {

        super.viewDidLoad()
        print("EczaneDetailPopupViewController viewDidLoad çağrıldı.")
        if let eczaneData = self.eczane {
            print("Alınan eczane verisi: \(eczaneData)")
        } else {
            print("EczaneDetailPopupViewController viewDidLoad içinde self.eczane nil.")
        }
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        
        configureView()
        setupEmbeddedMap()


    }
     
        

        func configureView() {
        guard let eczane = eczane else {
            print("configureView: self.eczane nil olduğu için view konfigüre edilemiyor.")
            eczaneAdiLabel.text = "Eczane Bilgisi Yok" 
            return
        }
        print("configureView: Eczane ile konfigüre ediliyor: \(eczane.name), Telefon: \(eczane.phone)")
        eczaneAdiLabel.text = eczane.name
        eczaneAdiLabel.numberOfLines = 0 // Uzun isimler için
    }




    func setupEmbeddedMap() {
        guard let eczane = eczane,
              !eczane.loc.isEmpty else {
            mapView.isHidden = true
            print("Eczane konumu bulunamadı (popup).")
            return
        }

        let locString = eczane.loc

        let coordinates = locString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        if coordinates.count == 2, let lat = Double(coordinates[0]), let lon = Double(coordinates[1]) {
            let pharmacyCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = pharmacyCoordinate
            annotation.title = eczane.name
            mapView.addAnnotation(annotation)
            
            let regionRadius: CLLocationDistance = 300
            let coordinateRegion = MKCoordinateRegion(center: pharmacyCoordinate,
                                                      latitudinalMeters: regionRadius,
                                                      longitudinalMeters: regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
            mapView.isHidden = false
        } else {
            mapView.isHidden = true
            print("Geçersiz koordinat formatı (popup): \(locString)")
        }
    }


    @IBAction func callButtonTapped(_ sender: UIButton) {
        
        guard let eczane = eczane else {
            print("callButtonTapped: self.eczane nil.")
            return
        }

        print("callButtonTapped: Telefon: '\(eczane.phone)'")


        guard !eczane.phone.isEmpty else {
            print("Aramak için telefon numarası yok. (eczane.phone boş geldi)")
            return
        }
        
        let phoneNumber = eczane.phone
        
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "telprompt://\(cleanedPhoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }  else {
            print("Arama yapılamıyor.")
        }
    }

    @IBAction func mapButtonTapped(_ sender: UIButton) {
        guard let eczane = eczane,  !eczane.loc.isEmpty else {
            print("Haritada açmak için konum bilgisi yok.")
            return
        }
        
        let locString = eczane.loc
        
        let coordinates = locString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        if coordinates.count == 2, let lat = Double(coordinates[0]), let lon = Double(coordinates[1]) {
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
            mapItem.name = eczane.name
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        } else {
            print("Haritada açmak için geçersiz koordinat formatı.")
        }
    }
    
}

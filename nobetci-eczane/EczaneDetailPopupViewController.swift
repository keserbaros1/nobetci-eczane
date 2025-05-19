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

    // Storyboard'dan bağlanacak IBOutlet'lar
    @IBOutlet weak var containerView: UIView! // Popup içeriğini tutacak ana view
    @IBOutlet weak var eczaneAdiLabel: UILabel!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    // @IBOutlet weak var closeButton: UIButton! // Kapatma butonu

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Arka planı yarı saydam yap
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // Container view'a köşe yuvarlaklığı verelim
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        
        configureView()
        setupEmbeddedMap()
        
        
        // Butonlara SF Symbol ataması (iOS 13+)
        if #available(iOS 13.0, *) {
            callButton.setImage(UIImage(systemName: "phone.fill"), for: .normal)
            callButton.tintColor = .systemGreen
            mapButton.setImage(UIImage(systemName: "map.fill"), for: .normal)
            mapButton.tintColor = .systemBlue
            //closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            //closeButton.tintColor = .gray
        } else {
            // iOS 13 öncesi için metinler kalabilir veya özel ikonlar kullanılabilir
            callButton.setTitle("Ara", for: .normal)
            mapButton.setTitle("Harita", for: .normal)
            //closeButton.setTitle("Kapat", for: .normal)
        }
    }
     
        
        
        
    func configureView() {
        guard let eczane = eczane else { return }
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

    // Storyboard'dan bağlanacak IBAction'lar
    @IBAction func callButtonTapped(_ sender: UIButton) {
        guard let eczane = eczane, !eczane.phone.isEmpty else {
            print("Aramak için telefon numarası yok.")
            return
        }
        
        let phoneNumber = eczane.phone
        
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let url = URL(string: "tel://\(cleanedPhoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
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
    /*
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
     */
}

//
//  LanguageSelectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 10/08/2025.
//

import UIKit
import Speech

class LanguagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    private var languages: [LanguageItem] = []
    private var filteredLanguages: [LanguageItem] = UserDataManager.main.languageItems
    
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Speech Languages"
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    
    private func setupUI() {
        // Search bar
        searchBar.placeholder = "Search language"
        searchBar.delegate = self
        view.addSubview(searchBar)
        
        // Table view
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
        // Layout
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLanguages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let item = filteredLanguages[indexPath.row]
        cell.textLabel?.text = "\(item.localizedString) (\(item.identifier))"
        cell.accessoryType = item.isSelected ? .checkmark : .none
        return cell
    }
    
    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = filteredLanguages[indexPath.row]
        
        // Clear all selections
        for lang in languages {
            lang.isSelected = false
        }
        
        // Mark selected
        selectedItem.isSelected = true
        
        tableView.reloadData()
    }
    
    // MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredLanguages = languages
        } else {
            filteredLanguages = languages.filter {
                $0.localizedString.localizedCaseInsensitiveContains(searchText) ||
                $0.identifier.localizedCaseInsensitiveContains(searchText)
            }
        }
        tableView.reloadData()
    }
}


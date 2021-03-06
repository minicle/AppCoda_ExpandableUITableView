//
//  ViewController.swift
//  Expandable
//
//  Created by Gabriel Theodoropoulos on 28/10/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

import UIKit

class ViewController: UIViewController{
  
  //存放各個cell的內容
  var cellDescriptors: NSMutableArray!
  //存放各個Section的可顯示Rows
  var visibleRowsPerSection = [[Int]]()
  
  // MARK: IBOutlet Properties
  
  @IBOutlet weak var tblExpandable: UITableView!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }
  
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    configureTableView()
    loadCellDescriptors()
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // MARK: Custom Functions
  
  func configureTableView() {
    
    tblExpandable.delegate = self
    tblExpandable.dataSource = self
    tblExpandable.tableFooterView = UIView(frame: CGRectZero)
    
    tblExpandable.registerNib(UINib(nibName: "NormalCell", bundle: nil), forCellReuseIdentifier: "idCellNormal")
    tblExpandable.registerNib(UINib(nibName: "TextfieldCell", bundle: nil), forCellReuseIdentifier: "idCellTextfield")
    tblExpandable.registerNib(UINib(nibName: "DatePickerCell", bundle: nil), forCellReuseIdentifier: "idCellDatePicker")
    tblExpandable.registerNib(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: "idCellSwitch")
    tblExpandable.registerNib(UINib(nibName: "ValuePickerCell", bundle: nil), forCellReuseIdentifier: "idCellValuePicker")
    tblExpandable.registerNib(UINib(nibName: "SliderCell", bundle: nil), forCellReuseIdentifier: "idCellSlider")
    
  }
  
  func loadCellDescriptors() {
    //取得CellDescriptor.plist資料
    if let path = NSBundle.mainBundle().pathForResource("CellDescriptor", ofType: "plist") {
      cellDescriptors = NSMutableArray(contentsOfFile: path)
      getIndicesOfVisibleRows()
      tblExpandable.reloadData()
    }
  }
  
  func getIndicesOfVisibleRows() {
    visibleRowsPerSection.removeAll()
    
    //取得每一個section要顯示的row，
    for currentSectionCells in cellDescriptors {
      var visibleRows = [Int]()
      
      for row in 0...((currentSectionCells as! [[String: AnyObject]]).count - 1) {
        // 0: false ， 1: true
        if currentSectionCells[row]["isVisible"] as! Bool == true {
          visibleRows.append(row)
        }
      }
      visibleRowsPerSection.append(visibleRows)
    }
  }
  
  //回傳cell的Dictionary
  func getCellDescriptorForIndexPath(indexPath: NSIndexPath) -> [String: AnyObject] {
    let indexOfVisibleRow = visibleRowsPerSection[indexPath.section][indexPath.row]
    let cellDescriptor = cellDescriptors[indexPath.section][indexOfVisibleRow] as! [String: AnyObject]
    return cellDescriptor
  }
  
}

// MARK: - UITableViewDelegate
extension ViewController : UITableViewDelegate{
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    let currentCellDescriptor = getCellDescriptorForIndexPath(indexPath)
    
    switch currentCellDescriptor["cellIdentifier"] as! String {
    case "idCellNormal":
      return 60.0
      
    case "idCellDatePicker":
      return 270.0
      
    default:
      return 44.0
    }
    
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    let indexOfTappedRow = visibleRowsPerSection[indexPath.section][indexPath.row]
    
    //判斷Cell是否能展開
    if cellDescriptors[indexPath.section][indexOfTappedRow]["isExpandable"] as! Bool == true {
      var shouldExpandAndShowSubRows = false
      
      //能展開的Cell尚未展開
      if cellDescriptors[indexPath.section][indexOfTappedRow]["isExpanded"] as! Bool == false {
        shouldExpandAndShowSubRows = true
      }
      
      //將新的開啟狀態寫回cellDescriptors（之後再次點擊才能做出正確反映）
      cellDescriptors[indexPath.section][indexOfTappedRow].setValue(shouldExpandAndShowSubRows, forKey: "isExpanded")
      
      //修改了某些 cell 的 isVisible 屬性，這導致整個可視 cell 的行數也改變了，因此，讓 App 重新計算可視 cell 的行索引(indexOfTappedRow + 1是不用包括Section的Header)
      for i in (indexOfTappedRow + 1)...(indexOfTappedRow + (cellDescriptors[indexPath.section][indexOfTappedRow]["additionalRows"] as! Int)) {
        cellDescriptors[indexPath.section][i].setValue(shouldExpandAndShowSubRows, forKey: "isVisible")
      }
      
    }else{
      
      // Favorite Sport & Favorite Color
      if cellDescriptors[indexPath.section][indexOfTappedRow]["cellIdentifier"] as! String == "idCellValuePicker" {
        var indexOfParentCell: Int!
        
        //找出頂層 cell 的行索引，也就是被點擊的 cell 的「父 cell」的行索引。實際上，我們只需要從這個 cell 的單元格描述向前搜索，所找到的第一個頂層 cell 就是我們要找的 cell（即第一個可展開的 cell）。
        for var i=indexOfTappedRow - 1; i>=0; --i {
          if cellDescriptors[indexPath.section][i]["isExpandable"] as! Bool == true {
            indexOfParentCell = i
            break
          }
        }
        
        //將選中的 cell 的值給頂層 cell 的 textLabel 的 text 屬性。
        cellDescriptors[indexPath.section][indexOfParentCell].setValue((tblExpandable.cellForRowAtIndexPath(indexPath) as! CustomCell).textLabel?.text, forKey: "primaryTitle")
        
        //將頂層 cell 的 expanded 標記為 false
        cellDescriptors[indexPath.section][indexOfParentCell].setValue(false, forKey: "isExpanded")
        
        //重新計算可視 cell 的行索引(indexOfTappedRow + 1是不用包括Section的Header)
        for i in (indexOfParentCell + 1)...(indexOfParentCell + (cellDescriptors[indexPath.section][indexOfParentCell]["additionalRows"] as! Int)) {
          cellDescriptors[indexPath.section][i].setValue(false, forKey: "isVisible")
        }
        
      }
    }
    
    //取得可視的row
    getIndicesOfVisibleRows()
    
    //刷新UITableView的該Section
    tblExpandable.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Fade)
  }
  
}

// MARK: - UITableViewDataSource
extension ViewController : UITableViewDataSource{
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    if cellDescriptors != nil {
      return cellDescriptors.count
    }
    else {
      return 0
    }
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return visibleRowsPerSection[section].count
  }
  
  func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0:
      return "Personal"
      
    case 1:
      return "Preferences"
      
    default:
      return "Work Experience"
    }
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let currentCellDescriptor = getCellDescriptorForIndexPath(indexPath)
    
    //多個xib設相同Class，利用Identifier來識別是要顯示哪種xib
    let cell = tableView.dequeueReusableCellWithIdentifier(currentCellDescriptor["cellIdentifier"] as! String, forIndexPath: indexPath) as! CustomCell
    
    if currentCellDescriptor["cellIdentifier"] as! String == "idCellNormal" {
      if let primaryTitle = currentCellDescriptor["primaryTitle"] {
        cell.textLabel?.text = primaryTitle as? String
      }
      
      if let secondaryTitle = currentCellDescriptor["secondaryTitle"] {
        cell.detailTextLabel?.text = secondaryTitle as? String
      }
    }else if currentCellDescriptor["cellIdentifier"] as! String == "idCellTextfield" {
      cell.textField.placeholder = currentCellDescriptor["primaryTitle"] as? String
    }else if currentCellDescriptor["cellIdentifier"] as! String == "idCellSwitch" {
      cell.lblSwitchLabel.text = currentCellDescriptor["primaryTitle"] as? String
      
      let value = currentCellDescriptor["value"] as? String
      cell.swMaritalStatus.on = (value == "true") ? true : false
    }else if currentCellDescriptor["cellIdentifier"] as! String == "idCellValuePicker" {
      cell.textLabel?.text = currentCellDescriptor["primaryTitle"] as? String
    }else if currentCellDescriptor["cellIdentifier"] as! String == "idCellSlider" {
      let value = currentCellDescriptor["value"] as! String
      cell.slExperienceLevel.value = (value as NSString).floatValue
    }
    
    cell.delegate = self
    
    return cell
  }
  
}


// MARK - CustomCellDelegate
extension ViewController : CustomCellDelegate{
  
  //日期選擇
  func dateWasSelected(selectedDateString: String) {
    let dateCellSection = 0
    let dateCellRow = 3
    
    cellDescriptors[dateCellSection][dateCellRow].setValue(selectedDateString, forKey: "primaryTitle")
    tblExpandable.reloadData()
  }
  
  
  func maritalStatusSwitchChangedState(isOn: Bool) {
    let maritalSwitchCellSection = 0
    let maritalSwitchCellRow = 6
    
    let valueToStore = (isOn) ? "true" : "false"
    let valueToDisplay = (isOn) ? "Married" : "Single"
    
    //將更改的內容儲存回cellDescriptors
    cellDescriptors[maritalSwitchCellSection][maritalSwitchCellRow].setValue(valueToStore, forKey: "value")
    
    //更新此Section的內容
    cellDescriptors[maritalSwitchCellSection][maritalSwitchCellRow - 1].setValue(valueToDisplay, forKey: "primaryTitle")
    
    tblExpandable.reloadData()
  }
  
  func textfieldTextWasChanged(newText: String, parentCell: CustomCell) {
    let parentCellIndexPath = tblExpandable.indexPathForCell(parentCell)
    
    let currentFullname = cellDescriptors[0][0]["primaryTitle"] as! String
    let fullnameParts = currentFullname.componentsSeparatedByString(" ")
    
    var newFullname = ""
    if parentCellIndexPath?.row == 1 {
      if fullnameParts.count == 2 {
        newFullname = "\(newText) \(fullnameParts[1])"
      }else {
        newFullname = newText
      }
    }else {
      newFullname = "\(fullnameParts[0]) \(newText)"
    }
    
    newFullname = ""
    
    cellDescriptors[0][0].setValue(newFullname, forKey: "primaryTitle")
    tblExpandable.reloadData()
  }
  
  func sliderDidChangeValue(newSliderValue: String) {
    cellDescriptors[2][0].setValue(newSliderValue, forKey: "primaryTitle")
    cellDescriptors[2][1].setValue(newSliderValue, forKey: "value")
    
    tblExpandable.reloadSections(NSIndexSet(index: 2), withRowAnimation: UITableViewRowAnimation.None)
  }
  
}



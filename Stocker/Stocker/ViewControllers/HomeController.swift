import UIKit
import Charts

class HomeController: UIViewController {
        
    @IBOutlet weak var homeTableView: UITableView!
    
    let identifiers : [String] = ["AppLogoTVC", "YieldTVC","PredictionTitleTVC", "PredictionTVC"]
    
    let sections : [String] = ["Others1","Others2","Others3" ,"Estimate"]
    let estivateSectionRows : [Int] = [0,1,2,3,4]
    var selected : [Bool] = [false,true,true,true,true]
    
    var stockerEstimateList : [StockerEstimate] = [] {
        didSet{
            self.homeTableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        homeTableView.dataSource = self
        self.homeTableView.estimatedRowHeight = 200
        self.homeTableView.rowHeight = UITableView.automaticDimension
        //Data Parsing
        getStockListData()
    }
        
    func getStockListData() {
        StockListAPI.shared.getStockListData(completion: { result in
            switch result {
            case .success(let stockList):
                stockList.map{ stockListItem in
                    self.getStockPriceData(stockListItem)
                }
            case .failure(let error):
                print("getStockListData : \(error)")
            }
        })
    }
    
    func getStockPriceData(_ stockListItem : StockList) {
        StockerChartAPI.shared.getStockerChartData(stockCode: stockListItem.stockCode, completion: { result in
            switch result {
            case .success(let data):
                let parsedLastPrice : [ChartDataEntry] =  data.lastPrice.enumerated().map{ (index, price) in
                    ChartDataEntry(x: Double(index), y: price)
                }
                
                let stockerEstimateItem : StockerEstimate = StockerEstimate(
                    stockCode: stockListItem.stockCode,
                    stockName: stockListItem.stockName,
                    stockPrice: stockListItem.stockPrice,
                    stockEstimatePrice: stockListItem.stockEstimatePrice,
                    lastTime: data.lastTime,
                    parsedLastPrice: parsedLastPrice
                )
                self.stockerEstimateList.append(stockerEstimateItem)
            
            case .failure(let error):
                print(error)
            }
        })
    }
}

extension HomeController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 3 {
            return estivateSectionRows.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            return self.homeTableView.dequeueReusableCell(withIdentifier: identifiers[indexPath.section], for: indexPath) as! AppLogoTVC
        } else if indexPath.section == 1 {
            return self.homeTableView.dequeueReusableCell(withIdentifier: identifiers[indexPath.section], for: indexPath) as! YieldTVC
        } else if indexPath.section == 2 {
            return  self.homeTableView.dequeueReusableCell(withIdentifier: identifiers[indexPath.section], for: indexPath) as! PredictionTitleTVC
        } else if indexPath.section == 3 {
            let cell = self.homeTableView.dequeueReusableCell(withIdentifier: identifiers[indexPath.section], for: indexPath) as! PredictionTVC

            cell.index = indexPath.row
            cell.delegate = self
            
            if self.stockerEstimateList.count == 5 {
                let listItem : StockerEstimate = self.stockerEstimateList[indexPath.row]
                var lastTime : String =  String(Int(round(listItem.lastTime)))
                lastTime.insert(":", at: lastTime.index(lastTime.startIndex, offsetBy: 2))
                
                cell.stockCodeLabel.text = listItem.stockCode
                cell.stockNameLabel.text = listItem.stockName
                cell.stockPriceLabel.text = decimalWon(Int(round(listItem.stockPrice)))
                cell.compareStockPriceRatioLabel.text = "0.34%"
                cell.stockEstimateLabel.text = decimalWon(Int(round(listItem.stockEstimatePrice)))
                cell.compareStockEstimateRatioLabel.text = "0.34%"
                cell.lastTimeLabel.text = lastTime + " 기준"
                cell.chartDataEntry = self.stockerEstimateList[indexPath.row].parsedLastPrice
                cell.chartLimitLineValue = self.stockerEstimateList[indexPath.row].stockEstimatePrice
  
                if self.selected[indexPath.row] {
                    cell.heightConstraint.constant = 300
                } else {
                    cell.heightConstraint.constant = 0
                }
            }
            
            return cell
        } else {
            return  self.homeTableView.dequeueReusableCell(withIdentifier: identifiers[indexPath.row]) as! PredictionTitleTVC
        }
    }
    
    func decimalWon(_ value: Int) -> String {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let result = numberFormatter.string(from: NSNumber(value: value))! + " 원"
            return result
    }
    
    func calRevenueRatio(key : String, xValue : Double, yValue : Double) -> Double {
        return 10.0
    }
}

extension HomeController : ComponentProductCellDelegate{
    func touchUpInside(index: Int) {
        self.selected[index] = !self.selected[index]
        self.homeTableView.reloadRows(at: [IndexPath.init(row: index, section: 3)], with: .fade)
    }
}

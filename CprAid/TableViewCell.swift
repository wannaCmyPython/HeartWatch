//
//  TableViewCell.swift
//  CprAid
//
//  Created by Daniel Greenberg on 11/18/18.
//  Copyright © 2018 Daniel Greenberg. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    //IBOutlets
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

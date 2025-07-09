# Tunnel Rock Mass Rating (RMR) Calculator - MATLAB GUI

A comprehensive MATLAB application for calculating Rock Mass Rating (RMR) specifically designed for tunnel engineering projects. This tool provides an intuitive graphical user interface for geotechnical engineers to assess rock mass quality and determine appropriate tunnel support requirements.

## Features

### 📊 **Complete RMR Assessment**
- **Uniaxial Compressive Strength (UCS)** evaluation with automatic rating calculation
- **Rock Quality Designation (RQD)** percentage assessment
- **Joint Spacing** analysis in meters
- **Joint Condition** evaluation with predefined categories
- **Groundwater Condition** assessment
- **Joint Orientation Adjustment** specifically for tunnel applications
![image](https://github.com/user-attachments/assets/76228872-5a8c-4883-ade8-704d2dcdbb27)


### 🎯 **Tunnel-Specific Calculations**
- Advanced joint orientation analysis considering tunnel azimuth
- Automatic adjustment factors for tunnel excavation geometry
- Integration with specialized orientation adjustment algorithms
- Real-time calculation of orientation-dependent stability factors

![image](https://github.com/user-attachments/assets/2d0cdce9-9a07-45e9-b70f-9d921560d6eb)
Note: ** 35 degree is a threshold assumption made in this code to definel a plane is perpendicular or parallel to the tunnel**
![image](https://github.com/user-attachments/assets/243f0ec3-6435-4679-9089-8b62cf4c9a08)

### 🖥️ **User-Friendly Interface**
- Clean, professional GUI with color-coded results
- Real-time parameter updates and calculations
- Resizable interface with normalized positioning
- Input validation and error handling
- Visual feedback for different rock quality classes

### 📈 **Engineering Output**
- **RMR Score** with automatic classification (Class I-V)
- **Rock Quality Classification** with color-coded indicators
- **Stand-up Time** estimations for different span lengths
- **Cohesion Values** for engineering design
- **Support Recommendations** based on RMR class

### 🔧 **Additional Tools**
- **Export Functionality**: Generate detailed reports in text format
- **Project Management**: Track project name, location, and date
- **Clear/Reset**: Quick data clearing for new calculations
- **Help System**: Comprehensive built-in documentation

## Technical Specifications

### Requirements
- MATLAB R2014b or later
- No additional toolboxes required
- Compatible with Windows, macOS, and Linux

### Input Parameters
- **UCS**: 0-500+ MPa range
- **RQD**: 0-100% range
- **Joint Spacing**: 0.01-10+ meters
- **Joint Dip**: 0-90 degrees
- **Dip Direction**: 0-360 degrees
- **Tunnel Azimuth**: 0-360 degrees

### Output Classifications
- **Class I (81-100)**: Very Good Rock - 10 years stand-up time for 15m span
- **Class II (61-80)**: Good Rock - 1 year stand-up time for 10m span
- **Class III (41-60)**: Fair Rock - 1 week stand-up time for 5m span
- **Class IV (21-40)**: Poor Rock - 10 hours stand-up time for 2.5m span
- **Class V (0-20)**: Very Poor Rock - 30 minutes stand-up time for 1m span

## Usage

1. **Launch the Application**
   ```matlab
   Rock_Mass_Rating_Matlab_Code()
   ```

2. **Input Rock Parameters**
   - Enter UCS, RQD, and joint spacing values
   - Select joint and groundwater conditions from dropdowns
   - Input tunnel and joint orientation data

3. **Calculate Joint Orientation**
   - Click "Calculate JO" to determine orientation adjustment
   - View real-time scoring and classification

4. **Review Results**
   - Check total RMR score and rock classification
   - Review engineering properties and recommendations
   - Export detailed reports for documentation

## Applications

### 🚇 **Tunnel Engineering**
- Metro and subway tunnel design
- Road and highway tunnel construction
- Mining tunnel stability assessment
- Underground facility excavation

### 🏗️ **Geotechnical Engineering**
- Rock mass characterization
- Slope stability analysis
- Foundation design in rock
- Underground excavation planning

### 📚 **Educational Use**
- Rock mechanics coursework
- Geotechnical engineering training
- Research and development
- Professional certification preparation


## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests to improve the calculator's functionality.


## Acknowledgments

- Based on the Bieniawski RMR classification system
- Incorporates tunnel-specific orientation adjustments
- Designed for practical engineering applications

## Keywords

`rock-mass-rating` `rmr` `tunnel-engineering` `geotechnical` `matlab` `gui` `rock-mechanics` `underground-excavation` `joint-orientation` `mining-engineering`

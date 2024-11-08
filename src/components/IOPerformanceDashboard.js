import React, { useState } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

const IOPerformanceDashboard = () => {
  const [selectedMetric, setSelectedMetric] = useState('bandwidth');
  
  // Organize the data
  const testData = {
    write: {
      '1M': [
        { threads: 1, bandwidth: 0.01, iops: 6.628898 },
        { threads: 4, bandwidth: 0.02, iops: 20.452512 },
        { threads: 8, bandwidth: 0.04, iops: 44.187735 },
        { threads: 16, bandwidth: 0.11, iops: 112.247561 }
      ],
      '4M': [
        { threads: 1, bandwidth: 0.02, iops: 5.788784 },
        { threads: 4, bandwidth: 0.07, iops: 18.375162 },
        { threads: 8, bandwidth: 0.17, iops: 42.880695 },
        { threads: 16, bandwidth: 0.32, iops: 81.601142 }
      ],
      '8M': [
        { threads: 1, bandwidth: 0.06, iops: 7.044834 },
        { threads: 4, bandwidth: 0.19, iops: 24.673488 },
        { threads: 8, bandwidth: 0.47, iops: 60.041916 },
        { threads: 16, bandwidth: 0.63, iops: 80.817125 }
      ],
      '16M': [
        { threads: 1, bandwidth: 0.05, iops: 2.939505 },
        { threads: 4, bandwidth: 0.19, iops: 11.904958 },
        { threads: 8, bandwidth: 0.29, iops: 18.607891 },
        { threads: 16, bandwidth: 1.08, iops: 69.105423 }
      ]
    },
    read: {
      '1M': [
        { threads: 1, bandwidth: 0.02, iops: 23.694866 },
        { threads: 4, bandwidth: 0.10, iops: 106.579364 },
        { threads: 8, bandwidth: 0.21, iops: 214.138184 },
        { threads: 16, bandwidth: 0.40, iops: 408.179925 }
      ],
      '4M': [
        { threads: 1, bandwidth: 0.18, iops: 45.902184 },
        { threads: 4, bandwidth: 0.18, iops: 46.445040 },
        { threads: 8, bandwidth: 0.79, iops: 203.130192 },
        { threads: 16, bandwidth: 1.03, iops: 263.285465 }
      ],
      '8M': [
        { threads: 1, bandwidth: 0.18, iops: 22.572423 },
        { threads: 4, bandwidth: 2.30, iops: 294.732115 },
        { threads: 8, bandwidth: 0.89, iops: 114.430477 },
        { threads: 16, bandwidth: 2.43, iops: 310.647439 }
      ],
      '16M': [
        { threads: 1, bandwidth: 0.51, iops: 32.332794 },
        { threads: 4, bandwidth: 1.78, iops: 113.869464 },
        { threads: 8, bandwidth: 4.76, iops: 304.609185 },
        { threads: 16, bandwidth: 4.63, iops: 296.289617 }
      ]
    }
  };

  return (
    <div className="space-y-8">
      <Card>
        <CardHeader>
          <CardTitle>GPFS I/O Performance Analysis</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="mb-4">
            <Select value={selectedMetric} onValueChange={setSelectedMetric}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Select metric" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="bandwidth">Bandwidth (MB/s)</SelectItem>
                <SelectItem value="iops">IOPS</SelectItem>
              </SelectContent>
            </Select>
          </div>
          
          {/* Read Performance Chart */}
          <div className="mb-8">
            <h3 className="text-lg font-medium mb-4">Read Performance</h3>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="threads" type="number" domain={[1, 16]} />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  {Object.entries(testData.read).map(([blockSize, data]) => (
                    <Line
                      key={blockSize}
                      data={data}
                      name={`${blockSize} Block Size`}
                      dataKey={selectedMetric}
                      stroke={blockSize === '1M' ? '#8884d8' : 
                             blockSize === '4M' ? '#82ca9d' : 
                             blockSize === '8M' ? '#ffc658' : 
                             '#ff7300'}
                      strokeWidth={2}
                    />
                  ))}
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Write Performance Chart */}
          <div>
            <h3 className="text-lg font-medium mb-4">Write Performance</h3>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="threads" type="number" domain={[1, 16]} />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  {Object.entries(testData.write).map(([blockSize, data]) => (
                    <Line
                      key={blockSize}
                      data={data}
                      name={`${blockSize} Block Size`}
                      dataKey={selectedMetric}
                      stroke={blockSize === '1M' ? '#8884d8' : 
                             blockSize === '4M' ? '#82ca9d' : 
                             blockSize === '8M' ? '#ffc658' : 
                             '#ff7300'}
                      strokeWidth={2}
                    />
                  ))}
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default IOPerformanceDashboard;
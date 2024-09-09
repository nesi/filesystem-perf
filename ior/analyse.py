import pandas as pd
import numpy as np
import argparse
from dateutil.parser import parse
import matplotlib.pyplot as plt
from matplotlib.dates import DateFormatter, DayLocator
from scipy import stats

def load_file(args,input):
    filter_from=None
    filter_to=None

    df=pd.read_csv(input,delimiter=',')
    df["time"]=pd.to_datetime(df["time"],format="%m/%d/%y %H:%M:%S")
    if not args.frm is None:
        filter_from=parse(args.frm,yearfirst=True)
    if not args.to is None:
        filter_to=parse(args.to,yearfirst=True)

    if filter_from and filter_to:
        df=df[(df['time']>=filter_from) & (df['time']<=filter_to)]
    elif filter_from:
        df=df[(df['time']>=filter_from)]
    elif filter_to:
        df=df[(df['time']<=filter_to)]

    #df = df.set_index('time')
#    df_daily = df.resample(args.resample,on='time').mean().interpolate()
    df_daily=df.set_index('time')
    if args.resample:
        df_daily = df_daily.resample(args.resample).mean().interpolate()
    df_daily.dropna(inplace=True)
    return df_daily

def outliers(data,maxz=3):
    list_of_outliers=[]
    avg=np.mean(data)
    stdev=np.std(data)
    if stdev==0:
        return []
    for i in range(len(data)):
        z=(data[i]-avg)/stdev
        if z>=maxz:
            list_of_outliers.append(i)
      
    return list_of_outliers

def main(args):
    colors=['r','g','b','y']
    cols=["Sequential","MPIIO","Random"]
    charts=["w1_bw","w2_bw","w3_bw","w1_iops","w2_iops","w3_iops","r1_bw","r2_bw","r3_bw",
            "r1_iops","r2_iops","r3_iops"]
    dfs=[]
    names=[item for item in args.input.split(',')]
    for i in names:
        print(i)
        d=load_file(args,i)
        print(d)
        dfs.append(d)

    fig, ax = plt.subplots(4,3,figsize=(19.20,9.83))

    for a, col in zip(ax[0], cols):
        a.set_title(col,ha='right', va='baseline')

    for i in range(len(dfs)):
        d=dfs[i]
        for j in range(len(charts)):
            lab=names[i] if j==0 else None
            if args.outlier>0:
                d=d[((d[charts[j]] - d[charts[j]].mean()) / d[charts[j]].std()).abs() < args.outlier]
#                outl=outliers(d[charts[j]],maxz=args.outlier)
#                avg=np.mean(d[charts[j]])
#                for ii in outl:
#                    pos=d[charts[j]].index[ii]
#                    val=d.loc[[pos]][charts[j]]
#                    d.iloc[[ii],[j]]=avg
#                    ax[j//3,j%3].axvline(pos,color=colors[i],linestyle='--',label=None)
            d[charts[j]].plot(ax=ax[j//3,j%3],color=colors[i],label=lab)


    lines_labels = [ax.get_legend_handles_labels() for ax in fig.axes]
    lines, labels = [sum(lol, []) for lol in zip(*lines_labels)]
    lines=lines[:len(dfs)]
    labels=labels[:len(dfs)]
    fig.legend(lines, labels)

    ax[0,0].set_ylabel("Write bw(MB/s)")
    ax[1,0].set_ylabel("Write iops")
    ax[2,0].set_ylabel("Read bw(MB/s)")
    ax[3,0].set_ylabel("Read iops")
    for i in range(4):
        for j in range(3):
            ax[i,j].grid(True)
            #ax[i,j].xaxis.set_major_locator(DayLocator(interval=1))
            #ax[i,j].xaxis.set_major_formatter(DateFormatter("%d/%m"))
    #fig.tight_layout()

    if args.output:
        plt.savefig(args.output, bbox_inches='tight')
    else:
        plt.show()


if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Process  files')
    parser.add_argument('--input', '-i', required=True, dest='input', nargs='?', help='Input file name')
    parser.add_argument('--output', '-o', required=False, dest='output', type=str, default=None, help='Output file name')
    parser.add_argument('--from', '-f', dest='frm', nargs='?', help='Filter records from this time')
    parser.add_argument('--to', '-t', dest='to', nargs='?', help='Filter records from to time')
    parser.add_argument('--resample', '-r', dest='resample', type=str, default=None,help='Resampling frequency')
    parser.add_argument('--outlier', '-l', required=False, dest='outlier', type=float, default=0, help='Max Z score for outlier detection')
    args = parser.parse_args()

    main(args)

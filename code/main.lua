require 'torch'
require 'paths'
require 'optim'
require 'nn'
require 'cutorch'
require 'gnuplot'

print('\n\n\n' .. os.date("%Y-%m-%d_%H-%M-%S") .. '\n')
local opts = require 'opts'
local opt = opts.parse(arg)

local util = require 'utils'(opt)
local load, loss, psnr = util:load()

local DataLoader = require 'dataloader'
local Trainer = require 'train'

print('loading model and criterion...')
local model = require 'model/init'(opt)
local criterion = require 'loss/init'(opt)

print('Creating data loader...')
local trainLoader, valLoader = DataLoader.create(opt)
local trainer = Trainer(model, criterion, opt)

if opt.valOnly then
    print('Validate the model (at epoch ' .. opt.startEpoch - 1 .. ') with ' .. opt.numVal .. ' val images')
    trainer:test(opt.startEpoch - 1, valLoader)
else
    print('Train start')
    for epoch = opt.startEpoch, opt.nEpochs do
        loss[epoch] = trainer:train(epoch, trainLoader)
        util:plot(loss,'loss')
        
        if opt.trainOnly then
            psnr[epoch] = trainer:test(epoch, valLoader)
            util:plot(psnr,'PSNR')
        end

        util:checkpoint(model, criterion, loss, psnr)
    end
end
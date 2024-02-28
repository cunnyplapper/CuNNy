/* minimal implementation of FSR using vulkan */
/* Copyright (C) 2024 cunnyplapper
 * SPDX-License-Identifier: MIT */
#include <stdio.h>
#include <stdlib.h>
#define STB_IMAGE_IMPLEMENTATION
#include <stb/stb_image.h>
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include <stb/stb_image_write.h>
#define GLAD_VULKAN_IMPLEMENTATION
#include "vulkan.h"

#define DIE() do { fprintf(stderr, "fail %u\n", __LINE__); exit(-1); } while (0)
#define ENSURE(x) if (!(x)) DIE()
#define VKENSURE(x) ENSURE((x) == VK_SUCCESS)
#define COUNTOF(x) (sizeof(x) / sizeof(*(x)))
#define MAX(x, y) ((x) > (y) ? (x) : (y))

typedef uint8_t u8;
typedef int32_t i32;
typedef uint32_t u32;
typedef float f32;

static u32 memidx(u32 bits, VkMemoryPropertyFlags props,
		  VkPhysicalDeviceMemoryProperties *pdmp)
{
	for (u32 i = 0; i < pdmp->memoryTypeCount; ++i) {
		if ((bits & (1 << i)) &&
		    ((pdmp->memoryTypes[i].propertyFlags & props) == props))
		    return i;
	}
	DIE();
	return 0;
}

static void trnsimg(VkCommandBuffer cb, VkImage img, VkImageLayout old,
		    VkImageLayout new, VkPipelineStageFlags srcstage,
		    VkPipelineStageFlags dststage, VkAccessFlags srcaccess,
		    VkAccessFlags dstaccess)
{
	VkImageMemoryBarrier bar = {
		.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
		.srcAccessMask = srcaccess,
		.dstAccessMask = dstaccess,
		.oldLayout = old,
		.newLayout = new,
		.image = img,
		.subresourceRange = {
			.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
			.levelCount = 1,
			.layerCount = 1
		}
	};
	vkCmdPipelineBarrier(cb, srcstage, dststage, 0, 0, NULL, 0, NULL, 1,
			     &bar);

}

int main(int argc, char *argv[])
{
	ENSURE(argc == 4);
	u32 rcas = 0;
	rcas = argv[3][0] - '0';
	ENSURE(rcas == 0 || rcas == 1);
	i32 w, h, ch;
	u32 inch = 1;
	u8 *pxs = stbi_load(argv[1], &w, &h, &ch, inch);
	ENSURE(pxs);
	f32 scale = 2.0f;
	char *end;
	i32 ow = (i32)(w * scale), oh = (i32)(h * scale);
	fprintf(stderr, "%dx%d -> %dx%d\n", w, h, ow, oh);
	ENSURE(gladLoaderLoadVulkan(NULL, NULL, NULL) != 0);
	VkApplicationInfo ai = {
		.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
		.pApplicationName = "",
		.pEngineName = "",
		.apiVersion = VK_API_VERSION_1_3
	};
	VkInstanceCreateInfo instci = {
		.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
		.pApplicationInfo = &ai
	};
#ifdef DEBUG
	char const *layer = "VK_LAYER_KHRONOS_validation";
	u32 nlayers;
	vkEnumerateInstanceLayerProperties(&nlayers, NULL);
	VkLayerProperties lps[nlayers];
	vkEnumerateInstanceLayerProperties(&nlayers, lps);
	for (u32 i = 0; i < nlayers; ++i) {
		if (strcmp(lps[i].layerName, layer) == 0) {
			instci.enabledLayerCount = 1;
			instci.ppEnabledLayerNames = &layer;
			break;
		}
	}
#endif
	VkInstance inst;
	VKENSURE(vkCreateInstance(&instci, NULL, &inst));
	u32 npdevs;
	vkEnumeratePhysicalDevices(inst, &npdevs, NULL);
	VkPhysicalDevice pdevs[npdevs];
	vkEnumeratePhysicalDevices(inst, &npdevs, pdevs);
	VkPhysicalDevice pdev = pdevs[0];
	u32 nqfs;
	vkGetPhysicalDeviceQueueFamilyProperties(pdev, &nqfs, NULL);
	VkQueueFamilyProperties qfps[nqfs];
	vkGetPhysicalDeviceQueueFamilyProperties(pdev, &nqfs, qfps);
	u32 qfi = 0;
	for (; qfi < nqfs; ++qfi) {
		VkQueueFamilyProperties props = qfps[qfi];
		if (props.queueCount > 0 &&
		    (props.queueFlags & VK_QUEUE_COMPUTE_BIT))
			break;
	}
	ENSURE(qfi != nqfs);
	VkDeviceQueueCreateInfo dqci = {
		.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
		.queueFamilyIndex = qfi,
		.queueCount = 1,
		.pQueuePriorities = (f32[]){1.0f}
	};
	VkPhysicalDeviceFeatures feats = {0};
	VkDeviceCreateInfo dci = {
		.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
		.pQueueCreateInfos = &dqci,
		.queueCreateInfoCount = 1,
		.pEnabledFeatures = &feats
	};
	VkDevice dev;
	VKENSURE(vkCreateDevice(pdev, &dci, NULL, &dev));
	VkQueue queue;
	vkGetDeviceQueue(dev, qfi, 0, &queue);
	u32 bufsz = MAX(w * h * inch, ow * oh);
	// I hate this api
	VkBuffer buf;
	VkBufferCreateInfo bci = {
		.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
		.size = bufsz,
		.usage = (VK_BUFFER_USAGE_TRANSFER_SRC_BIT |
			  VK_BUFFER_USAGE_TRANSFER_DST_BIT)
	};
	VKENSURE(vkCreateBuffer(dev, &bci, NULL, &buf));
	VkMemoryRequirements mr;
	vkGetBufferMemoryRequirements(dev, buf, &mr);
	VkPhysicalDeviceMemoryProperties pdmp;
	vkGetPhysicalDeviceMemoryProperties(pdev, &pdmp);
	VkMemoryAllocateInfo mai = {
		.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
		.allocationSize = bufsz,
		.memoryTypeIndex = memidx(
			mr.memoryTypeBits,
			(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT |
			 VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT),
			&pdmp)
	};
	VkDeviceMemory bufmem;
	VKENSURE(vkAllocateMemory(dev, &mai, NULL, &bufmem));
	VKENSURE(vkBindBufferMemory(dev, buf, bufmem, 0));
	void *bufp;
	VKENSURE(vkMapMemory(dev, bufmem, 0, VK_WHOLE_SIZE, 0, &bufp));
	memcpy(bufp, pxs, w * h * inch);
	stbi_image_free(pxs);
	VkImage iimg, easuimg, rcasimg;
	VkImageCreateInfo ici = {
		.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
		.imageType = VK_IMAGE_TYPE_2D,
		.extent.depth = 1,
		.mipLevels = 1,
		.arrayLayers = 1,
		.samples = VK_SAMPLE_COUNT_1_BIT,
		.tiling = VK_IMAGE_TILING_OPTIMAL,
		.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED
	};
	ici.extent.width = w;
	ici.extent.height = h;
	ici.format = VK_FORMAT_R8_UNORM;
	ici.usage = (VK_IMAGE_USAGE_TRANSFER_DST_BIT |
		     VK_IMAGE_USAGE_SAMPLED_BIT);
	VKENSURE(vkCreateImage(dev, &ici, NULL, &iimg));
	ici.extent.width = ow;
	ici.extent.height = oh;
	ici.format = VK_FORMAT_R8_UNORM;
	ici.usage = (VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
		     VK_IMAGE_USAGE_STORAGE_BIT);
	VKENSURE(vkCreateImage(dev, &ici, NULL, &easuimg));
	VKENSURE(vkCreateImage(dev, &ici, NULL, &rcasimg));
	VkDeviceMemory imem, easumem, rcasmem;
	vkGetImageMemoryRequirements(dev, iimg, &mr);
	mai.allocationSize = mr.size;
	mai.memoryTypeIndex = memidx(
		mr.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &pdmp);
	VKENSURE(vkAllocateMemory(dev, &mai, NULL, &imem));
	VKENSURE(vkBindImageMemory(dev, iimg, imem, 0));
	vkGetImageMemoryRequirements(dev, easuimg, &mr);
	mai.allocationSize = mr.size;
	mai.memoryTypeIndex = memidx(
		mr.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &pdmp);
	VKENSURE(vkAllocateMemory(dev, &mai, NULL, &easumem));
	VKENSURE(vkBindImageMemory(dev, easuimg, easumem, 0));
	vkGetImageMemoryRequirements(dev, rcasimg, &mr);
	mai.allocationSize = mr.size;
	mai.memoryTypeIndex = memidx(
		mr.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &pdmp);
	VKENSURE(vkAllocateMemory(dev, &mai, NULL, &rcasmem));
	VKENSURE(vkBindImageMemory(dev, rcasimg, rcasmem, 0));
	VkImageView iimgv, easuimgv, rcasimgv;
	VkImageViewCreateInfo ivci = {
		.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
		.viewType = VK_IMAGE_VIEW_TYPE_2D,
		.subresourceRange = {
			.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
			.levelCount = 1,
			.layerCount = 1
		}
	};
	ivci.image = iimg;
	ivci.format = VK_FORMAT_R8_UNORM;
	VKENSURE(vkCreateImageView(dev, &ivci, NULL, &iimgv));
	ivci.image = easuimg;
	ivci.format = VK_FORMAT_R8_UNORM;
	VKENSURE(vkCreateImageView(dev, &ivci, NULL, &easuimgv));
	ivci.image = rcasimg;
	ivci.format = VK_FORMAT_R8_UNORM;
	VKENSURE(vkCreateImageView(dev, &ivci, NULL, &rcasimgv));
	VkSampler smplr;
	VkSamplerCreateInfo sci = {
		.sType = VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO,
		.magFilter = VK_FILTER_LINEAR,
		.minFilter = VK_FILTER_LINEAR,
		.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
		.addressModeV = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
		.addressModeW = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE,
		.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR
	};
	VKENSURE(vkCreateSampler(dev, &sci, NULL, &smplr));
	VkDescriptorSetLayoutBinding dslb[] = {
		{
			.binding = 0,
			.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			.descriptorCount = 1,
			.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT
		},
		{
			.binding = 1,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
			.descriptorCount = 1,
			.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT
		},
		{
			.binding = 2,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
			.descriptorCount = 1,
			.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT
		}
	};
	VkDescriptorSetLayoutCreateInfo dslci = {
		.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
		.bindingCount = COUNTOF(dslb),
		.pBindings = dslb
	};
	VkDescriptorSetLayout dsl;
	VKENSURE(vkCreateDescriptorSetLayout(dev, &dslci, NULL, &dsl));
	VkDescriptorPoolSize dps[] = {
		{
			.type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			.descriptorCount = 1
		},
		{
			.type = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
			.descriptorCount = 2
		}
	};
	VkDescriptorPoolCreateInfo dpci = {
		.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
		.maxSets = 1,
		.poolSizeCount = COUNTOF(dps),
		.pPoolSizes = dps
	};
	VkDescriptorPool dp;
	vkCreateDescriptorPool(dev, &dpci, NULL, &dp);
	VkDescriptorSetAllocateInfo dsai = {
		.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
		.descriptorPool = dp,
		.descriptorSetCount = 1,
		.pSetLayouts = &dsl
	};
	VkDescriptorSet ds;
	VKENSURE(vkAllocateDescriptorSets(dev, &dsai, &ds));
	VkWriteDescriptorSet wds[] = {
		{
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = ds,
			.dstBinding = 0,
			.descriptorCount = 1,
			.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			.pImageInfo = &(VkDescriptorImageInfo){
				.sampler = smplr,
				.imageView = iimgv,
				.imageLayout = VK_IMAGE_LAYOUT_READ_ONLY_OPTIMAL
			}
		},
		{
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = ds,
			.dstBinding = 1,
			.descriptorCount = 1,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
			.pImageInfo = (VkDescriptorImageInfo[]){{
				.imageView = easuimgv,
				.imageLayout = VK_IMAGE_LAYOUT_GENERAL
			}}
		},
		{
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = ds,
			.dstBinding = 2,
			.descriptorCount = 1,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
			.pImageInfo = (VkDescriptorImageInfo[]){{
				.imageView = rcasimgv,
				.imageLayout = VK_IMAGE_LAYOUT_GENERAL
			}}
		}
	};
	vkUpdateDescriptorSets(dev, COUNTOF(wds), wds, 0, NULL);
	VkCommandPoolCreateInfo cpci = {
		.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
		.queueFamilyIndex = qfi,
		.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT
	};
	FILE *f = fopen("scripts/fsr.spv", "rb");
	ENSURE(f);
	fseek(f, 0, SEEK_END);
	u32 fsz = ftell(f);
	fseek(f, 0, SEEK_SET);
	u32 *spv = malloc(fsz);
	fread(spv, 1, fsz, f);
	fclose(f);
	VkShaderModuleCreateInfo smci = {
		.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
		.pCode = spv,
		.codeSize = fsz
	};
	VkShaderModule sm;
	VKENSURE(vkCreateShaderModule(dev, &smci, NULL, &sm));
	typedef struct {
		f32 x, y;
	} Vec2;
	struct {
		Vec2 insz, outsz;
		u32 pass;
	} pc = {{w, h}, {ow, oh}, 0};
	VkPushConstantRange pcr = {
		.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT,
		.size = sizeof(pc)
	};
	VkPipelineLayoutCreateInfo pllci = {
		.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
		.setLayoutCount = 1,
		.pSetLayouts = &dsl,
		.pushConstantRangeCount = 1,
		.pPushConstantRanges = &pcr
	};
	VkPipelineLayout pll;
	VKENSURE(vkCreatePipelineLayout(dev, &pllci, NULL, &pll));
	VkPipelineShaderStageCreateInfo plssci = {
		.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
		.stage = VK_SHADER_STAGE_COMPUTE_BIT,
		.module = sm,
		.pName = "main"
	};
	VkComputePipelineCreateInfo cplci = {
		.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO,
		.stage = plssci,
		.layout = pll
	};
	VkPipeline pl;
	VKENSURE(vkCreateComputePipelines(dev, NULL, 1, &cplci, NULL, &pl));
	VkCommandPool cp;
	VKENSURE(vkCreateCommandPool(dev, &cpci, NULL, &cp));
	VkCommandBufferAllocateInfo cbai = {
		.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
		.commandPool = cp,
		.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
		.commandBufferCount = 1
	};
	VkCommandBuffer cb;
	VKENSURE(vkAllocateCommandBuffers(dev, &cbai, &cb));
	VkCommandBufferBeginInfo cbbi = {
		.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
	};
	VKENSURE(vkBeginCommandBuffer(cb, &cbbi));
	trnsimg(cb, iimg, VK_IMAGE_LAYOUT_UNDEFINED,
		VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
		VK_PIPELINE_STAGE_TRANSFER_BIT,
		0, VK_ACCESS_TRANSFER_WRITE_BIT);
	VkBufferImageCopy bic = {
		.imageSubresource = {
			.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
			.layerCount = 1
		},
		.imageExtent.depth = 1
	};
	bic.imageExtent.width = w;
	bic.imageExtent.height = h;
	vkCmdCopyBufferToImage(
		cb, buf, iimg, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &bic);
	trnsimg(cb, iimg, VK_IMAGE_LAYOUT_UNDEFINED,
		VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		VK_PIPELINE_STAGE_TRANSFER_BIT,
		VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
		VK_ACCESS_TRANSFER_WRITE_BIT, VK_ACCESS_SHADER_READ_BIT);
	trnsimg(cb, easuimg, VK_IMAGE_LAYOUT_UNDEFINED,
		VK_IMAGE_LAYOUT_GENERAL,
		VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
		VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
		0, VK_ACCESS_SHADER_WRITE_BIT);
	trnsimg(cb, rcasimg, VK_IMAGE_LAYOUT_UNDEFINED,
		VK_IMAGE_LAYOUT_GENERAL,
		VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
		VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
		0, VK_ACCESS_SHADER_WRITE_BIT);
	vkCmdBindPipeline(cb, VK_PIPELINE_BIND_POINT_COMPUTE, pl);
	vkCmdBindDescriptorSets(cb, VK_PIPELINE_BIND_POINT_COMPUTE, pll, 0, 1,
				&ds, 0, NULL);
	vkCmdPushConstants(cb, pll, VK_SHADER_STAGE_COMPUTE_BIT, 0, sizeof(pc),
			   &pc);
	vkCmdDispatch(cb, (ow + 7) / 8, (oh + 7) / 8, 1);
	VkImage outimg = easuimg;
	if (rcas) {
		pc.pass = 1;
		vkCmdPushConstants(cb, pll, VK_SHADER_STAGE_COMPUTE_BIT, 0,
				   sizeof(pc), &pc);
		vkCmdDispatch(cb, (ow + 7) / 8, (oh + 7) / 8, 1);
		outimg = rcasimg;
	}
	trnsimg(cb, outimg, VK_IMAGE_LAYOUT_GENERAL,
		VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
		VK_PIPELINE_STAGE_TRANSFER_BIT,
		VK_ACCESS_SHADER_WRITE_BIT, VK_ACCESS_TRANSFER_READ_BIT);
	bic.imageExtent.width = ow;
	bic.imageExtent.height = oh;
	vkCmdCopyImageToBuffer(
		cb, outimg, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL, buf, 1,
		&bic);
	VKENSURE(vkEndCommandBuffer(cb));
	VkSubmitInfo si = {
		.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
		.commandBufferCount = 1,
		.pCommandBuffers = &cb
	};
	VKENSURE(vkQueueSubmit(queue, 1, &si, VK_NULL_HANDLE));
	VKENSURE(vkQueueWaitIdle(queue));
	u8 *tmp = malloc(bufsz);
	memcpy(tmp, bufp, bufsz);
	fprintf(stderr, "done vk\n");
	stbi_write_png_compression_level = 0;
	stbi_write_png(argv[2], ow, oh, 1, tmp, ow);
	fprintf(stderr, "ok\n");
	return 0;
}
